import Foundation
import Security

struct PlexConfig {
    let plexServerUrl: String
    let plexToken: String
}

class ConfigManager {
    static let shared = ConfigManager()

    private let keychainService = "com.plexwidget.credentials"
    private let tokenAccount = "plex-token"
    private let serverUrlKey = "plex-server-url"

    private init() {}

    func loadConfig() -> PlexConfig? {
        // Load from Keychain
        if let token = loadTokenFromKeychain(),
           let serverUrl = loadServerUrlFromUserDefaults() {
            return PlexConfig(plexServerUrl: serverUrl, plexToken: token)
        }

        return nil
    }

    func saveConfig(serverUrl: String, token: String) -> Bool {
        // Save server URL to UserDefaults (non-sensitive)
        UserDefaults.standard.set(serverUrl, forKey: serverUrlKey)

        // Save token to Keychain (secure)
        return saveTokenToKeychain(token)
    }

    // MARK: - Keychain Operations

    private func saveTokenToKeychain(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else { return false }

        // Delete any existing token first
        deleteTokenFromKeychain()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: tokenData,
            // Use most restrictive access level - only accessible when device is unlocked
            // and data is not backed up to iCloud or transferred to other devices
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            return nil
        }

        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenAccount
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - UserDefaults Operations

    private func loadServerUrlFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: serverUrlKey)
    }
}
