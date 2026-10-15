import Foundation

struct TokenStore {
    private let keychain = KeychainStore()
    private let key = "accessToken"

    var accessToken: String? { keychain.read(key) }

    func save(_ token: String) {
        keychain.save(token, for: key)
    }

    func clear() {
        keychain.delete(key)
    }
}
