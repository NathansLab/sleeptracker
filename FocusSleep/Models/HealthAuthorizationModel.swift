import Foundation

@MainActor
final class HealthAuthorizationModel: ObservableObject {
    enum AuthorizationState {
        case unknown
        case authorized
        case denied
    }

    @Published private(set) var state: AuthorizationState = .unknown

    init() {
        Task {
            await refreshStatus()
        }
    }

    func requestAuthorization() async {
        do {
            try await HealthStoreManager.shared.requestAuthorizationIfNeeded()
            state = .authorized
        } catch {
            state = .denied
        }
    }

    private func refreshStatus() async {
        do {
            try await HealthStoreManager.shared.requestAuthorizationIfNeeded()
            state = .authorized
        } catch {
            state = .denied
        }
    }
}
