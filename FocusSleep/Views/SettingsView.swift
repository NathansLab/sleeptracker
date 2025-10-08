import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: FocusSessionHistoryStore

    @State private var exportError: String?
    @State private var exportResult: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Verlauf") {
                    Button("Verlauf als JSON exportieren") {
                        exportHistory()
                    }
                    if let exportResult {
                        ShareLink(item: exportResult)
                    }
                    if let exportError {
                        Text(exportError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("Support") {
                    Link("Anleitung in der Kurzbefehle-App öffnen", destination: URL(string: "shortcuts://gallery")!)
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    private func exportHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessionStore.sessions)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("FocusSleepSessions.json")
            try data.write(to: url, options: .atomic)
            exportResult = url
            exportError = nil
        } catch {
            exportError = "Export fehlgeschlagen: \(error.localizedDescription)"
            exportResult = nil
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FocusSessionHistoryStore())
}
