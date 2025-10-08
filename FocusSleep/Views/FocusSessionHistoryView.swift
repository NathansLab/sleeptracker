import SwiftUI

struct FocusSessionHistoryView: View {
    var sessions: [FocusSession]

    var body: some View {
        GroupBox("Verlauf") {
            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Noch keine Fokus-Sitzungen erfasst.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sessions) { session in
                        FocusSessionRow(session: session)
                        if session.id != sessions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct FocusSessionRow: View {
    var session: FocusSession

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var durationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.focusName ?? "Fokus")
                    .font(.headline)
                Spacer()
                if let recorded = session.recordedDuration,
                   let formatted = durationFormatter.string(from: recorded) {
                    Label(formatted, systemImage: "bed.double.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(session.recordedToHealth ? .blue : .secondary)
                }
            }

            Text("\(dateFormatter.string(from: session.startDate)) – \(dateFormatter.string(from: session.endDate))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !session.recordedToHealth {
                Text("Nicht nach Health übertragen (Dauer zu kurz/lang oder nicht über Nacht).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    FocusSessionHistoryView(
        sessions: [
            FocusSession(
                startDate: .now.addingTimeInterval(-3600 * 8),
                endDate: .now,
                focusName: "Schlafen",
                recordedStartDate: .now.addingTimeInterval(-3600 * 6),
                recordedEndDate: .now,
                recordedToHealth: true
            ),
            FocusSession(
                startDate: .now.addingTimeInterval(-3600 * 20),
                endDate: .now.addingTimeInterval(-3600 * 15),
                focusName: "Arbeiten",
                recordedStartDate: nil,
                recordedEndDate: nil,
                recordedToHealth: false
            )
        ]
    )
}
