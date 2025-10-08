import SwiftUI

@main
struct FocusSleepApp: App {
    @StateObject private var sessionStore = FocusSessionHistoryStore()
    @StateObject private var authorizationModel = HealthAuthorizationModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(authorizationModel)
        }
    }
}
