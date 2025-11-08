import Foundation

struct PlexConfig: Codable {
    let plexServerUrl: String
    let plexToken: String
}

class ConfigManager {
    static let shared = ConfigManager()

    private init() {}

    func loadConfig() -> PlexConfig? {
        // Try to load from the same directory as the original config.json
        let configPaths = [
            // Development path (relative to project)
            FileManager.default.currentDirectoryPath + "/../config.json",
            // App bundle path
            Bundle.main.bundlePath + "/../../config.json",
            // Home directory
            FileManager.default.homeDirectoryForCurrentUser.path + "/.plex-widget/config.json"
        ]

        for configPath in configPaths {
            let url = URL(fileURLWithPath: configPath)
            if let data = try? Data(contentsOf: url),
               let config = try? JSONDecoder().decode(PlexConfig.self, from: data) {
                print("Loaded config from: \(configPath)")
                return config
            }
        }

        print("No config file found. Searched paths:")
        configPaths.forEach { print("  - \($0)") }
        return nil
    }
}
