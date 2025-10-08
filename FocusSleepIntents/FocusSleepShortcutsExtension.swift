import AppIntents

struct FocusSleepShortcutsExtension: AppIntentsExtension {
    var configuration: AppIntentsExtensionConfiguration {
        AppIntentsExtensionConfiguration(
            displayName: "FocusSleep Kurzbefehle",
            description: "Automatisches Tracking von Fokuszeiten"
        )
    }
}
