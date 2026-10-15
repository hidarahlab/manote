import Foundation

/// Satu-satunya jalur catatan ke server: kirim perubahan perangkat, terima keadaan server.
struct NotesRepository {
    var api = APIClient()

    func sync(since: String?, changes: [Note]) async throws -> NoteSyncResponse {
        try await api.post(
            "/api/notes/sync",
            body: NoteSyncRequest(since: since, changes: changes.map(NoteSyncRequest.Change.init))
        )
    }
}
