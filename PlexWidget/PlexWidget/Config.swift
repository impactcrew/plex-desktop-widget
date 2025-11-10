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

    func hasCompletedOnboarding() -> Bool {
        // Check UserDefaults only (doesn't trigger Keychain permission)
        return loadServerUrlFromUserDefaults() != nil
    }

    func loadConfig() -> PlexConfig? {
        #if DEBUG
        // TEMPORARY: Load from UserDefaults for testing
        if let serverUrl = UserDefaults.standard.string(forKey: serverUrlKey),
           let token = UserDefaults.standard.string(forKey: "plex-token-debug") {
            return PlexConfig(plexServerUrl: serverUrl, plexToken: token)
        }
        return nil
        #else
        // Load from Keychain
        if let token = loadTokenFromKeychain(),
           let serverUrl = loadServerUrlFromUserDefaults() {
            return PlexConfig(plexServerUrl: serverUrl, plexToken: token)
        }
        return nil
        #endif
    }

    func saveConfig(serverUrl: String, token: String) -> Bool {
        // TEMPORARY: Save both to UserDefaults for testing
        #if DEBUG
        UserDefaults.standard.set(serverUrl, forKey: serverUrlKey)
        UserDefaults.standard.set(token, forKey: "plex-token-debug")
        print("DEBUG: Saved to UserDefaults only (skipping Keychain)")
        return true
        #else
        // Save token to Keychain first (secure) - this is the critical operation
        guard saveTokenToKeychain(token) else {
            return false
        }

        // Only save server URL to UserDefaults if Keychain save succeeded
        UserDefaults.standard.set(serverUrl, forKey: serverUrlKey)
        return true
        #endif
    }

    // MARK: - Keychain Operations

    private func saveTokenToKeychain(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else {
            print("DEBUG: Failed to convert token to data")
            return false
        }

        // Delete any existing token first
        deleteTokenFromKeychain()

        // For sandboxed apps, we need simpler keychain access without password prompts
        // Using kSecAttrAccessibleAfterFirstUnlock allows the app to access the keychain
        // after the user logs in, without requiring additional authentication
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        print("DEBUG: Keychain save status: \(status) (errSecSuccess = \(errSecSuccess))")
        if status != errSecSuccess {
            print("DEBUG: Keychain error: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")")
        }
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
