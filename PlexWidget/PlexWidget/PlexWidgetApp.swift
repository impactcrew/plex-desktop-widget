import SwiftUI

@main
struct PlexWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusBarItem: NSStatusItem?
    var plexMonitor = PlexAppMonitor.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if Plex is running, quit if not
        plexMonitor.quitIfPlexNotRunning()

        // Create the floating window
        let screenWidth = NSScreen.main?.frame.width ?? 1920
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 120
        let xPosition = screenWidth - windowWidth - 20
        let yPosition: CGFloat = 20

        window = NSWindow(
            contentRect: NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true

        // Set content view
        let contentView = ContentView()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        // Prevent window from appearing in Mission Control
        window.collectionBehavior.insert(.transient)

        // Create menu bar item (optional - for showing/hiding widget)
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Plex Widget")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Widget", action: #selector(showWidget), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide Widget", action: #selector(hideWidget), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem?.menu = menu
    }

    @objc func showWidget() {
        window.orderFront(nil)
    }

    @objc func hideWidget() {
        window.orderOut(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
