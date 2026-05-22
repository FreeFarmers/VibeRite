//
//  KeychainStore.swift
//  VibeRite
//

import Foundation
import Security

enum KeychainStore {
    static let cloudflareTokenKey = "viberite.cloudflare.apiToken"

    @discardableResult
    static func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier,
            kSecValueData as String: data,
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: AppConstants.bundleIdentifier,
        ]

        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
