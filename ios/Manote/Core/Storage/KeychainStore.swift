import Foundation
import Security
import os

struct KeychainStore {
    private static let logger = Logger(subsystem: "com.hidarahlab.manote", category: "Keychain")

    var service = "com.hidarahlab.manote"

    func read(_ key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String, for key: String) {
        delete(key)
        var query = baseQuery(key)
        query[kSecValueData as String] = Data(value.utf8)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Self.logger.error("Gagal menyimpan \(key, privacy: .public) ke Keychain: \(status)")
        }
    }

    func delete(_ key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
    }

    private func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
