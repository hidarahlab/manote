import SwiftUI
import WidgetKit

struct ManoteEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    /// Waktu mulai tugas berikutnya sudah tiba.
    var isTaskDue: Bool {
        guard let start = snapshot.nextTaskStart else { return false }
        return start <= date
    }

    /// Ada yang mendesak: tugas yang waktunya tiba, atau kartu yang tenggatnya tinggal 1 hari.
    var isUrgent: Bool { isTaskDue || snapshot.urgentCards > 0 }
}

struct ManoteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ManoteEntry {
        ManoteEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (ManoteEntry) -> Void) {
        completion(ManoteEntry(date: .now, snapshot: context.isPreview ? .preview : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ManoteEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        var entries = [ManoteEntry(date: .now, snapshot: snapshot)]
        // Tepat saat tugas berikutnya mulai, widget berganti ke tampilan "waktunya mulai".
        if let start = snapshot.nextTaskStart, start > .now {
            entries.append(ManoteEntry(date: start, snapshot: snapshot))
        }
        completion(Timeline(entries: entries, policy: .after(Date.now.addingTimeInterval(30 * 60))))
    }
}

struct ManoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ManoteEntry

    var body: some View {
        Group {
            if !entry.snapshot.isLoggedIn {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manote")
                        .font(.system(.headline, design: .rounded))
                    Text("Buka Manote dan login untuk melihat ringkasan.")
                        .font(.caption)
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    nextTask
                    Spacer(minLength: 8)
                    if family == .systemSmall {
                        Text("\(entry.snapshot.pendingTasks) tugas belum selesai")
                            .font(.caption2)
                            .opacity(0.85)
                    } else {
                        HStack(spacing: 10) {
                            stat(entry.snapshot.pendingTasks, "Tugas", "alarm")
                            stat(entry.snapshot.notes, "Catatan", "note.text")
                            stat(entry.snapshot.openCards, "Kartu", "rectangle.split.3x1")
                        }
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) {
            // Ungu Manote; merah saat ada yang mendesak.
            entry.isUrgent ? Color(red: 0.64, green: 0.18, blue: 0.18) : Color(red: 0.33, green: 0.29, blue: 0.72)
        }
        .widgetURL(URL(string: "manote://tasks"))
    }

    @ViewBuilder
    private var nextTask: some View {
        if let title = entry.snapshot.nextTaskTitle, let start = entry.snapshot.nextTaskStart {
            VStack(alignment: .leading, spacing: 2) {
                Label(entry.isTaskDue ? "Waktunya mulai" : "Tugas berikutnya", systemImage: "alarm")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.85)
                Text(title)
                    .font(.system(family == .systemSmall ? .headline : .title3, design: .rounded).weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute().locale(Locale(identifier: "id_ID"))))
                    .font(.caption)
                    .opacity(0.85)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("Manote", systemImage: "checkmark.circle")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.85)
                Text("Tidak ada tugas menunggu")
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(2)
            }
        }
    }

    private func stat(_ value: Int, _ label: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Label("\(value)", systemImage: systemImage)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption2)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ManoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: ManoteTimelineProvider()) { entry in
            ManoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Manote")
        .description("Tugas berikutnya dan ringkasan catatan serta kerjaan.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ManoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        ManoteWidget()
    }
}

extension WidgetSnapshot {
    /// Contoh isi untuk galeri widget.
    static let preview = WidgetSnapshot(
        nextTaskTitle: "Rapat vendor", nextTaskStart: Date.now.addingTimeInterval(3600),
        pendingTasks: 3, notes: 12, openCards: 5, urgentCards: 0, isLoggedIn: true
    )
}
