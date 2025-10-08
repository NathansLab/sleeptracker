import Foundation
import Combine

@MainActor
final class FocusSessionHistoryStore: ObservableObject {
    @Published private(set) var sessions: [FocusSession] = []

    private var changeObserver: NSObjectProtocol?

    init() {
        registerForChanges()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    func reload() async {
        do {
            let history = try await FocusSessionStorage.shared.loadHistory()
            sessions = history
        } catch {
            print("FocusSessionHistoryStore failed to load history:", error)
        }
    }

    func append(_ session: FocusSession) {
        sessions.insert(session, at: 0)
        sessions = Array(sessions.prefix(60))
    }

    private func registerForChanges() {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else { return }
        changeObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.reload()
            }
        }
    }
}
