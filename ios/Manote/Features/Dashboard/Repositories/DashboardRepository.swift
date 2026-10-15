import Foundation

struct DashboardRepository {
    var api = APIClient()

    func summary() async throws -> DashboardSummary {
        try await api.get("/api/dashboard/summary")
    }
}
