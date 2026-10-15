import Foundation

/// Satu tugas: nama dan kapan harus mulai. Alarm berbunyi pada waktu mulainya.
/// Disimpan di perangkat seperti catatan, jadi bisa dibuat tanpa server.
struct TaskItem: Codable, Identifiable, Hashable {
    let id: UUID
    /// ID di server; `nil` selama tugas belum pernah sampai ke server.
    var serverId: Int?
    var title: String
    /// Keterangan tambahan, misalnya isi catatan asal tugas ini.
    var details: String = ""
    var startAt: Date
    /// Terisi berarti tugas selesai: alarmnya dimatikan atau tugasnya dicentang.
    var doneAt: Date?
    var createdAt: Date
    var updatedAt: Date
    /// Sudah dihapus di perangkat tetapi server belum diberi tahu.
    var isDeleted = false
    /// Ada perubahan di perangkat yang belum sampai ke server.
    var isDirty = false
}

extension TaskItem {
    // Ditulis sendiri supaya file tugas yang tersimpan sebelum ada `details` tetap terbaca.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        serverId = try container.decodeIfPresent(Int.self, forKey: .serverId)
        title = try container.decode(String.self, forKey: .title)
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        startAt = try container.decode(Date.self, forKey: .startAt)
        doneAt = try container.decodeIfPresent(Date.self, forKey: .doneAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        isDirty = try container.decodeIfPresent(Bool.self, forKey: .isDirty) ?? false
    }

    var isDone: Bool { doneAt != nil }

    /// Waktu mulainya sudah tiba dan tugas belum selesai: alarmnya sedang atau sudah berbunyi.
    func isDue(now: Date = .now) -> Bool {
        !isDone && startAt <= now
    }

    var startText: String {
        Self.startText(for: startAt)
    }

    /// Dipakai juga oleh notifikasi tugas, termasuk yang ditunda ke waktu lain.
    static func startText(for date: Date) -> String {
        let text = date.formatted(
            .dateTime.day().month(.wide).year().hour().minute().locale(Locale(identifier: "id_ID"))
        )
        return "Mulai \(text)"
    }
}
