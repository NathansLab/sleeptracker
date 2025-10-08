import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: FocusSessionHistoryStore
    @EnvironmentObject private var authorizationModel: HealthAuthorizationModel
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AppSummaryCard()
                    AutomationSetupCard()
                    HealthAccessCard()
                    NightBoundaryCard()
                    FocusSessionHistoryView(sessions: sessionStore.sessions)
                }
                .padding()
            }
            .navigationTitle("FocusSleep")
            .toolbar {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Einstellungen")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(sessionStore)
            }
        }
        .task {
            await sessionStore.reload()
        }
    }
}

private struct AppSummaryCard: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Automatisches Schlaftracking", systemImage: "bed.double")
                    .font(.headline)
                Text("FocusSleep protokolliert deine Fokuszeiten automatisch als Schlafzeit, sobald sie über deine Nachtgrenze hinausgehen.")
                    .font(.body)
                Text("Einmal eingerichtet, läuft alles lokal und datenschutzfreundlich.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AutomationSetupCard: View {
    var body: some View {
        GroupBox("Schnellstart") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lege zwei Kurzbefehls-Automationen an, um FocusSleep mit deinem Fokus zu verbinden:")
                VStack(alignment: .leading, spacing: 8) {
                    Label("Wenn Fokus aktiviert wird → StartFocusSession", systemImage: "play.fill")
                    Label("Wenn Fokus deaktiviert wird → StopFocusSession", systemImage: "stop.fill")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                Text("Die Intents findest du nach der Installation direkt in der Kurzbefehle-App unter 'Fokus'.")
                    .font(.callout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct HealthAccessCard: View {
    @EnvironmentObject private var authorizationModel: HealthAuthorizationModel

    var body: some View {
        GroupBox("Health-Freigabe") {
            VStack(alignment: .leading, spacing: 12) {
                Text("FocusSleep schreibt nur den Zeitraum \"Im Bett\" in Apple Health.")
                if authorizationModel.state == .authorized {
                    Label("Freigabe aktiv", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                } else {
                    Label("Freigabe benötigt", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.headline)
                    Button("Health-Zugriff anfragen") {
                        Task {
                            await authorizationModel.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct NightBoundaryCard: View {
    @AppStorage(
        "nightBoundaryMinutes",
        store: UserDefaults(suiteName: AppGroup.identifier)
    ) private var nightBoundaryMinutes: Int = NightBoundary().minutesAfterMidnight

    var body: some View {
        GroupBox("Nachtgrenze") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fokuszeiten, die über diese Uhrzeit hinaus gehen, werden als Schlaf interpretiert.")
                HStack {
                    Image(systemName: "moon.zzz")
                    Text(boundaryText)
                        .font(.headline)
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                let calendar = Calendar.current
                                let startOfDay = calendar.startOfDay(for: .now)
                                return calendar.date(byAdding: .minute, value: nightBoundaryMinutes, to: startOfDay) ?? .now
                            },
                            set: { newValue in
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: newValue)
                                let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                                nightBoundaryMinutes = minutes
                                let defaults = UserDefaults(suiteName: AppGroup.identifier)!
                                NightBoundaryStore.save(
                                    NightBoundary(minutesAfterMidnight: minutes),
                                    to: defaults
                                )
                            }
                        ),
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }
                .labelStyle(.titleAndIcon)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var boundaryText: String {
        let hours = nightBoundaryMinutes / 60
        let minutes = nightBoundaryMinutes % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? .now
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusSessionHistoryStore())
        .environmentObject(HealthAuthorizationModel())
}
