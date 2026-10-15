import Foundation

/// Satu-satunya jalur tugas ke server: kirim perubahan perangkat, terima keadaan server.
struct TasksRepository {
    var api = APIClient()

    func sync(since: String?, changes: [TaskItem]) async throws -> TaskSyncResponse {
        try await api.post(
            "/api/tasks/sync",
            body: TaskSyncRequest(since: since, changes: changes.map(TaskSyncRequest.Change.init))
        )
    }
}
