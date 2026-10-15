import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repository = AuthRepository()

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    func login() async -> User? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await handlingErrorsLocally {
                try await repository.login(username: username, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
