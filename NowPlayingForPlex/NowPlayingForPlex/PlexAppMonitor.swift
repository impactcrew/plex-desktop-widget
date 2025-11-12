import Foundation
import AppKit

class PlexAppMonitor: ObservableObject {
    static let shared = PlexAppMonitor()

    @Published var isPlexRunning = false
    private var workspace: NSWorkspace

    private init() {
        workspace = NSWorkspace.shared
        checkPlexRunning()
        setupNotifications()
    }

    private func setupNotifications() {
        // Monitor app launches
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        // Monitor app terminations
        workspace.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            if isPlexApp(app) {
                print("Plex app launched: \(app.localizedName ?? "Unknown")")
                isPlexRunning = true
            }
        }
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            if isPlexApp(app) {
                print("Plex app terminated: \(app.localizedName ?? "Unknown")")
                isPlexRunning = false

                // Quit this widget when Plex quits
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private func isPlexApp(_ app: NSRunningApplication) -> Bool {
        guard let bundleId = app.bundleIdentifier else { return false }

        // Check for Plex desktop apps
        let plexBundleIds = [
            "tv.plex.desktop",           // Plex for Mac
            "com.plexapp.plex",          // Alternative Plex bundle ID
            "tv.plex.player.desktop"     // Plex HTPC
        ]

        return plexBundleIds.contains(bundleId) ||
               bundleId.lowercased().contains("plex")
    }

    private func checkPlexRunning() {
        let runningApps = workspace.runningApplications
        isPlexRunning = runningApps.contains { isPlexApp($0) }

        if isPlexRunning {
            print("Plex is already running")
        }
    }

    func quitIfPlexNotRunning() {
        if !isPlexRunning {
            print("Plex is not running, quitting widget...")
            NSApplication.shared.terminate(nil)
        }
    }

    deinit {
        workspace.notificationCenter.removeObserver(self)
    }
}
