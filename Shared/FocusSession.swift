import Foundation

public struct FocusSession: Codable, Identifiable, Hashable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let focusName: String?
    public let recordedStartDate: Date?
    public let recordedEndDate: Date?
    public let recordedToHealth: Bool

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        focusName: String?,
        recordedStartDate: Date?,
        recordedEndDate: Date?,
        recordedToHealth: Bool
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.focusName = focusName
        self.recordedStartDate = recordedStartDate
        self.recordedEndDate = recordedEndDate
        self.recordedToHealth = recordedToHealth
    }

    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    public var recordedDuration: TimeInterval? {
        guard let recordedStartDate, let recordedEndDate else { return nil }
        return recordedEndDate.timeIntervalSince(recordedStartDate)
    }
}
