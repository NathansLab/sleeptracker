# FocusSleep

FocusSleep ist eine iOS-App, die Schlafzeiten automatisch anhand deiner Fokuszustände erkennt und in Apple Health als "Time in Bed" speichert. Über persönliche Kurzbefehle-Automationen starten und stoppen die App-Intents die Erfassung im Hintergrund – ganz ohne Watch oder zusätzliche Sensoren.

## Features

- **Fokus-Tracking:** Start- und Endzeiten werden beim Aktivieren bzw. Deaktivieren eines Fokus aufgezeichnet.
- **Nachtlogik:** Fokusphasen, die über eine konfigurierbare Nachtgrenze (Standard 01:00 Uhr) hinauslaufen, werden als Schlaf interpretiert.
- **HealthKit-Integration:** Validierte Zeiträume werden als `sleepAnalysis(.inBed)` in Apple Health geschrieben.
- **Plausibilitätsprüfung:** Intervalle über 10 Stunden oder ohne Nachtanteil werden ignoriert.
- **Datenschutz:** Alle Daten verbleiben lokal in der App-Gruppe oder in Apple Health.
- **Statistiken:** Die App zeigt Verlauf, Dauer und Übertragungsstatus deiner Fokusphasen.

## Aufbau

```
FocusSleep.xcodeproj/      # Xcode-Projektdateien
FocusSleep/                # SwiftUI-App
FocusSleepIntents/         # App-Intents-Erweiterung für Kurzbefehle
Shared/                    # Gemeinsame Modelle & Services (App + Extension)
```

## Einrichtung

1. Projekt in Xcode öffnen und ein eigenes Bundle Identifier + Team für App und Extension vergeben.
2. App auf einem Gerät mit iOS 17 (oder neuer) installieren.
3. Beim ersten Start in der App den HealthKit-Zugriff anfragen.
4. In der Kurzbefehle-App zwei persönliche Automationen anlegen:
   - **Wenn Fokus „Schlafen“ eingeschaltet wird → StartFocusSessionIntent ausführen**
   - **Wenn Fokus „Schlafen“ ausgeschaltet wird → StopFocusSessionIntent ausführen**
5. Optional in der App die Nachtgrenze (Standard 01:00 Uhr) anpassen.

## Anforderungen

- Xcode 15
- iOS 17 oder neuer
- HealthKit-Berechtigung zum Schreiben von Schlafdaten
- Aktivierter Fokus (z. B. Schlaf-Fokus) mit Automationen in Kurzbefehle

## Datenschutz

FocusSleep verarbeitet keine Cloud-Daten. Sitzungen werden in einer App-Gruppe gespeichert, damit App und Extension darauf zugreifen können. Schlafwerte werden ausschließlich in Apple Health geschrieben und lassen sich dort jederzeit löschen.
