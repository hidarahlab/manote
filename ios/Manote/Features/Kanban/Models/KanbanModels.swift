import Foundation

/// Kolom papan kanban, urut dari kiri ke kanan.
enum CardStatus: String, Codable, CaseIterable, Identifiable {
    case backlog = "BACKLOG"
    case todo = "TODO"
    case inProgress = "IN_PROGRESS"
    case review = "REVIEW"
    case done = "DONE"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .backlog: "Backlog"
        case .todo: "Todo"
        case .inProgress: "In Progress"
        case .review: "Review"
        case .done: "Done"
        }
    }
}

/// Satu "kerjaan": papan kanban berisi kartu-kartu. Disimpan di perangkat seperti catatan,
/// jadi bisa dibuat tanpa server.
struct Board: Codable, Identifiable, Hashable {
    let id: UUID
    /// ID di server; `nil` selama kerjaan belum pernah sampai ke server.
    var serverId: Int?
    var name: String
    var createdAt: Date
    var updatedAt: Date
    /// Sudah dihapus di perangkat tetapi server belum diberi tahu.
    var isDeleted = false
    /// Ada perubahan di perangkat yang belum sampai ke server.
    var isDirty = false
}

struct Card: Codable, Identifiable, Hashable {
    let id: UUID
    var serverId: Int?
    let boardId: UUID
    var title: String
    var description: String
    var status: CardStatus
    /// Urutan di dalam kolomnya; yang lebih kecil di atas. Tidak harus berurutan rapat.
    var position: Int
    /// Tenggat kartu; `nil` berarti tidak ada tenggat.
    var deadlineAt: Date?
    /// Kapan kartu masuk ke Done; `nil` selama belum selesai.
    var doneAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var isDeleted = false
    var isDirty = false
}

/// Tingkat kedekatan tenggat, penentu warna kartu.
enum DeadlineLevel {
    /// Tanpa tenggat: abu-abu.
    case none
    /// Lebih dari 2 hari lagi: hijau muda.
    case safe
    /// Tinggal 2 hari: kuning.
    case soon
    /// Tinggal 1 hari: merah.
    case urgent
    /// Sudah lewat tenggat: hitam.
    case overdue
    /// Kartu di Done: hijau, apa pun tenggatnya.
    case done
}

extension Card {
    private static let day: TimeInterval = 24 * 60 * 60

    func deadlineLevel(now: Date = .now) -> DeadlineLevel {
        if status == .done { return .done }
        guard let deadlineAt else { return .none }
        let remaining = deadlineAt.timeIntervalSince(now)
        if remaining <= 0 { return .overdue }
        if remaining <= Self.day { return .urgent }
        if remaining <= 2 * Self.day { return .soon }
        return .safe
    }

    var deadlineText: String? {
        deadlineAt.map { "Tenggat \(Self.shortText($0))" }
    }

    /// Subjudul kartu di Done. Kartu yang belum punya waktu selesai memakai waktu ubah terakhirnya.
    var doneText: String {
        "Done date \(Self.shortText(doneAt ?? updatedAt))"
    }

    private static func shortText(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "id_ID")))
    }
}
