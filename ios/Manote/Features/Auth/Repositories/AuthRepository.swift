import Foundation

struct AuthRepository {
    var api = APIClient()
    var tokenStore = TokenStore()

    var hasToken: Bool { tokenStore.accessToken != nil }

    func login(username: String, password: String) async throws -> User {
        let response: LoginResponse = try await api.post(
            "/api/auth/login",
            body: LoginRequest(username: username, password: password),
            authenticated: false
        )
        tokenStore.save(response.accessToken)
        return response.user
    }

    func currentUser() async throws -> User {
        try await api.get("/api/auth/me")
    }

    func logout() {
        tokenStore.clear()
    }
}
