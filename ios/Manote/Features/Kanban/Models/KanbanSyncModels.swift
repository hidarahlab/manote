import Foundation

struct KanbanSyncRequest: Encodable {
    struct BoardChange: Encodable {
        let clientId: UUID
        let name: String
        let updatedAt: Date
        let deleted: Bool

        init(_ board: Board) {
            clientId = board.id
            name = board.name
            updatedAt = board.updatedAt
            deleted = board.isDeleted
        }
    }

    struct CardChange: Encodable {
        let clientId: UUID
        let boardClientId: UUID
        let title: String
        let description: String
        let status: CardStatus
        let position: Int
        let deadlineAt: Date?
        let doneAt: Date?
        let updatedAt: Date
        let deleted: Bool

        init(_ card: Card) {
            clientId = card.id
            boardClientId = card.boardId
            title = card.title
            description = card.description
            status = card.status
            position = card.position
            deadlineAt = card.deadlineAt
            doneAt = card.doneAt
            updatedAt = card.updatedAt
            deleted = card.isDeleted
        }
    }

    /// Penanda dari sinkron sebelumnya, dikirim balik apa adanya; `nil` berarti minta semua.
    let since: String?
    let boards: [BoardChange]
    let cards: [CardChange]
}

struct KanbanSyncResponse: Decodable {
    struct SyncedBoard: Decodable {
        let id: Int
        let clientId: UUID
        let name: String
        let createdAt: Date
        let updatedAt: Date
        let deleted: Bool
    }

    struct SyncedCard: Decodable {
        let id: Int
        let clientId: UUID
        let boardClientId: UUID
        let title: String
        let description: String
        let status: CardStatus
        let position: Int
        let deadlineAt: Date?
        let doneAt: Date?
        let createdAt: Date
        let updatedAt: Date
        let deleted: Bool
    }

    let cursor: String
    let boards: [SyncedBoard]
    let cards: [SyncedCard]
}
