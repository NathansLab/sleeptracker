import Foundation

public struct PreparedFocusSession: Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let focusName: String?
    public let recordedStartDate: Date?
    public let recordedEndDate: Date?
    public let eligibleForHealthExport: Bool
}

public actor FocusSessionStorage {
    public static let shared = FocusSessionStorage()

    private struct PendingSession: Codable {
        var id: UUID
        var startDate: Date
        var focusName: String?
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let currentSessionKey = "currentFocusSession"
    private let historyKey = "focusSessionHistory"

    private init() {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
            fatalError("Unable to create UserDefaults for app group \(AppGroup.identifier)")
        }
        self.defaults = defaults
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    @discardableResult
    public func startSession(at date: Date = Date(), focusName: String?) async throws -> UUID {
        let pending = PendingSession(id: UUID(), startDate: date, focusName: focusName)
        let data = try encoder.encode(pending)
        defaults.set(data, forKey: currentSessionKey)
        return pending.id
    }

    public func hasActiveSession() -> Bool {
        defaults.data(forKey: currentSessionKey) != nil
    }

    public func abandonCurrentSession() {
        defaults.removeObject(forKey: currentSessionKey)
    }

    public func prepareCompletedSession(
        at endDate: Date = Date(),
        focusName: String?
    ) async throws -> PreparedFocusSession? {
        guard let data = defaults.data(forKey: currentSessionKey) else {
            return nil
        }

        defaults.removeObject(forKey: currentSessionKey)

        let pending = try decoder.decode(PendingSession.self, from: data)
        return try evaluateSession(
            id: pending.id,
            startDate: pending.startDate,
            endDate: endDate,
            focusName: focusName ?? pending.focusName
        )
    }

    public func storeCompletedSession(
        id: UUID,
        startDate: Date,
        endDate: Date,
        focusName: String?,
        recordedStart: Date?,
        recordedEnd: Date?,
        recordedToHealth: Bool
    ) throws -> FocusSession {
        let session = FocusSession(
            id: id,
            startDate: startDate,
            endDate: endDate,
            focusName: focusName,
            recordedStartDate: recordedStart,
            recordedEndDate: recordedEnd,
            recordedToHealth: recordedToHealth
        )

        var history = try loadHistory()
        history.insert(session, at: 0)
        history = Array(history.prefix(60))
        let data = try encoder.encode(history)
        defaults.set(data, forKey: historyKey)
        return session
    }

    public func updateSessionRecordStatus(id: UUID, recordedToHealth: Bool) throws {
        var history = try loadHistory()
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        let original = history[index]
        let updated = FocusSession(
            id: original.id,
            startDate: original.startDate,
            endDate: original.endDate,
            focusName: original.focusName,
            recordedStartDate: original.recordedStartDate,
            recordedEndDate: original.recordedEndDate,
            recordedToHealth: recordedToHealth
        )
        history[index] = updated
        let data = try encoder.encode(history)
        defaults.set(data, forKey: historyKey)
    }

    public func loadHistory() throws -> [FocusSession] {
        guard let data = defaults.data(forKey: historyKey) else {
            return []
        }
        return try decoder.decode([FocusSession].self, from: data)
    }

    private func evaluateSession(
        id: UUID,
        startDate: Date,
        endDate: Date,
        focusName: String?
    ) throws -> PreparedFocusSession? {
        guard endDate > startDate else { return nil }

        let duration = endDate.timeIntervalSince(startDate)
        let maxDuration: TimeInterval = 60 * 60 * 10
        if duration > maxDuration {
            return PreparedFocusSession(
                id: id,
                startDate: startDate,
                endDate: endDate,
                focusName: focusName,
                recordedStartDate: nil,
                recordedEndDate: nil,
                eligibleForHealthExport: false
            )
        }

        let boundary = NightBoundaryStore.load(from: defaults)
        let calendar = Calendar.current
        guard let trimmedStart = trimmedSleepStart(
            for: startDate,
            endDate: endDate,
            boundary: boundary,
            calendar: calendar
        ) else {
            return PreparedFocusSession(
                id: id,
                startDate: startDate,
                endDate: endDate,
                focusName: focusName,
                recordedStartDate: nil,
                recordedEndDate: nil,
                eligibleForHealthExport: false
            )
        }

        guard trimmedStart < endDate else {
            return PreparedFocusSession(
                id: id,
                startDate: startDate,
                endDate: endDate,
                focusName: focusName,
                recordedStartDate: nil,
                recordedEndDate: nil,
                eligibleForHealthExport: false
            )
        }

        return PreparedFocusSession(
            id: id,
            startDate: startDate,
            endDate: endDate,
            focusName: focusName,
            recordedStartDate: trimmedStart,
            recordedEndDate: endDate,
            eligibleForHealthExport: true
        )
    }

    private func trimmedSleepStart(
        for startDate: Date,
        endDate: Date,
        boundary: NightBoundary,
        calendar: Calendar
    ) -> Date? {
        let minutes = boundary.minutesAfterMidnight
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let boundaryToday = calendar.date(byAdding: .minute, value: minutes, to: startOfDay) else {
            return nil
        }

        if startDate <= boundaryToday && endDate > boundaryToday {
            return boundaryToday
        }

        let boundaryNextDay = calendar.date(byAdding: .day, value: 1, to: boundaryToday)!
        if startDate <= boundaryNextDay && endDate > boundaryNextDay {
            return boundaryNextDay
        }

        return nil
    }
}
