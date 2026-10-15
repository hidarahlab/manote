import Foundation

struct TaskSyncRequest: Encodable {
    struct Change: Encodable {
        let clientId: UUID
        let title: String
        let description: String
        let startAt: Date
        let doneAt: Date?
        let updatedAt: Date
        let deleted: Bool

        init(_ task: TaskItem) {
            clientId = task.id
            title = task.title
            description = task.details
            startAt = task.startAt
            doneAt = task.doneAt
            updatedAt = task.updatedAt
            deleted = task.isDeleted
        }
    }

    /// Penanda dari sinkron sebelumnya, dikirim balik apa adanya; `nil` berarti minta semua.
    let since: String?
    let changes: [Change]
}

struct TaskSyncResponse: Decodable {
    struct SyncedTask: Decodable {
        let id: Int
        let clientId: UUID
        let title: String
        let description: String?
        let startAt: Date
        let doneAt: Date?
        let createdAt: Date
        let updatedAt: Date
        let deleted: Bool
    }

    let cursor: String
    let tasks: [SyncedTask]
}
