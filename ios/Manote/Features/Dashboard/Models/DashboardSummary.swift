import Foundation

struct DashboardSummary: Codable, Equatable {
    struct Notes: Codable, Equatable {
        let total: Int
        let latestTitle: String?
    }

    struct Kanban: Codable, Equatable {
        let todo: Int
        let inProgress: Int
        let done: Int
    }

    struct Tasks: Codable, Equatable {
        let pending: Int
        let nextTitle: String?
    }

    let notes: Notes
    let kanban: Kanban
    /// Kosong pada ringkasan yang tersimpan sebelum fitur Tugas ada.
    let tasks: Tasks?
}
