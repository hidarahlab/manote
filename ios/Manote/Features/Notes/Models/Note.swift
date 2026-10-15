import Foundation

/// Catatan seperti yang tersimpan di perangkat. `id` dibuat di perangkat, jadi catatan
/// bisa dibuat tanpa server.
struct Note: Codable, Identifiable, Hashable {
    let id: UUID
    /// ID di server; `nil` selama catatan belum pernah sampai ke server.
    var serverId: Int?
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var reminderAt: Date?
    /// Sudah dihapus di perangkat tetapi server belum diberi tahu.
    var isDeleted = false
    /// Ada perubahan di perangkat yang belum sampai ke server.
    var isDirty = false
}

struct NoteDraft: Equatable {
    var title: String
    var content: String

    var isBlank: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Note {
    private var contentLines: [Substring] {
        content.split(whereSeparator: \.isNewline).filter { !$0.allSatisfy(\.isWhitespace) }
    }

    /// Judul untuk ditampilkan: judul catatan, atau baris pertama isinya jika judul kosong.
    var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }
        return contentLines.first.map(String.init) ?? "Tanpa judul"
    }

    var preview: String {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (hasTitle ? contentLines : Array(contentLines.dropFirst())).joined(separator: " ")
    }

    var reminderText: String? {
        reminderAt.map { date in
            date.formatted(
                .dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "id_ID"))
            )
        }
    }

    func updatedText(relativeTo now: Date = .now) -> String {
        if now.timeIntervalSince(updatedAt) < 60 { return "Diubah baru saja" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        return "Diubah \(formatter.localizedString(for: updatedAt, relativeTo: now))"
    }
}
