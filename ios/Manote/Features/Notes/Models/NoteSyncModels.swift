import Foundation

struct NoteSyncRequest: Encodable {
    struct Change: Encodable {
        let clientId: UUID
        let title: String
        let content: String
        let reminderAt: Date?
        let updatedAt: Date
        let deleted: Bool

        init(_ note: Note) {
            clientId = note.id
            title = note.title
            content = note.content
            reminderAt = note.reminderAt
            updatedAt = note.updatedAt
            deleted = note.isDeleted
        }
    }

    /// Penanda dari sinkron sebelumnya, dikirim balik apa adanya; `nil` berarti minta semua.
    let since: String?
    let changes: [Change]
}

struct NoteSyncResponse: Decodable {
    struct SyncedNote: Decodable {
        let id: Int
        let clientId: UUID
        let title: String
        let content: String
        let createdAt: Date
        let updatedAt: Date
        let reminderAt: Date?
        let deleted: Bool
    }

    let cursor: String
    let notes: [SyncedNote]
}
