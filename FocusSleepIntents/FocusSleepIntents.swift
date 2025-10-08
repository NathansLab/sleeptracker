import AppIntents
import Foundation

struct StartFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "StartFocusSession"
    static var description = IntentDescription("Markiert den Start einer Fokusphase für FocusSleep.")

    @Parameter(title: "Fokusname", default: "Fokus")
    var focusName: String

    func perform() async throws -> some IntentResult {
        _ = try await FocusSessionStorage.shared.startSession(at: Date(), focusName: focusName)
        return .result()
    }
}

struct StopFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "StopFocusSession"
    static var description = IntentDescription("Beendet eine Fokusphase, prüft die Nachtgrenze und schreibt ggf. in Apple Health.")

    @Parameter(title: "Fokusname", default: "Fokus")
    var focusName: String

    func perform() async throws -> some IntentResult {
        guard let prepared = try await FocusSessionStorage.shared.prepareCompletedSession(
            at: Date(),
            focusName: focusName
        ) else {
            return .result(dialog: "Keine aktive Fokusphase gefunden.")
        }

        let storedSession = try await FocusSessionStorage.shared.storeCompletedSession(
            id: prepared.id,
            startDate: prepared.startDate,
            endDate: prepared.endDate,
            focusName: prepared.focusName,
            recordedStart: prepared.recordedStartDate,
            recordedEnd: prepared.recordedEndDate,
            recordedToHealth: false
        )

        guard prepared.eligibleForHealthExport,
              let recordedStart = prepared.recordedStartDate,
              let recordedEnd = prepared.recordedEndDate else {
            return .result(dialog: "Fokusphase gespeichert, aber nicht nach Health übertragen.")
        }

        do {
            try await HealthStoreManager.shared.saveInBedSession(start: recordedStart, end: recordedEnd)
            try await FocusSessionStorage.shared.updateSessionRecordStatus(id: storedSession.id, recordedToHealth: true)
            return .result(dialog: "Schlafphase in Health gespeichert.")
        } catch {
            try await FocusSessionStorage.shared.updateSessionRecordStatus(id: storedSession.id, recordedToHealth: false)
            return .result(dialog: "Speichern in Health fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}

struct FocusSleepShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .indigo

    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: StartFocusSessionIntent(),
                phrases: ["Starte FocusSleep", "FocusSleep Start"],
                shortTitle: "Start",
                systemImageName: "moon.zzz"
            ),
            AppShortcut(
                intent: StopFocusSessionIntent(),
                phrases: ["Stoppe FocusSleep", "FocusSleep Ende"],
                shortTitle: "Stop",
                systemImageName: "sunrise"
            )
        ]
    }
}
