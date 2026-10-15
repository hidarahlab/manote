import Foundation

/// Satu-satunya jalur kerjaan ke server: kirim perubahan perangkat, terima keadaan server.
struct KanbanRepository {
    var api = APIClient()

    func sync(since: String?, boards: [Board], cards: [Card]) async throws -> KanbanSyncResponse {
        try await api.post(
            "/api/boards/sync",
            body: KanbanSyncRequest(
                since: since,
                boards: boards.map(KanbanSyncRequest.BoardChange.init),
                cards: cards.map(KanbanSyncRequest.CardChange.init)
            )
        )
    }
}
