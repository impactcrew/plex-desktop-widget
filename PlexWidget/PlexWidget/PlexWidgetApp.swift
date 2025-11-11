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

// Custom NSWindow subclass that can accept keyboard input in borderless mode
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var onboardingWindow: NSWindow?
    var statusBarItem: NSStatusItem?
    var settingsWindow: NSWindow?
    lazy var settings = WidgetSettings.shared
    var clickOutsideMonitor: Any?
    var cachedConfig: PlexConfig? // Cache config to avoid multiple Keychain accesses

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if user has completed onboarding AND config can be loaded
        // This prevents corrupted state where URL exists but token doesn't
        if !ConfigManager.shared.hasCompletedOnboarding() || ConfigManager.shared.loadConfig() == nil {
            // Show onboarding - use regular activation policy to show window
            NSApp.setActivationPolicy(.regular)
            showOnboarding()
        } else {
            // Show main widget - use accessory activation policy (menu bar only)
            NSApp.setActivationPolicy(.accessory)
            showMainWidget()
        }

        // Create menu bar item with Plex chevron icon
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem?.button {
            // Create the Plex chevron icon from SVG path
            let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                NSColor.black.setFill()
                let path = NSBezierPath()
                // Plex chevron polygon: "117.9,33.9 104.1,13.5 118.3,13.5 132,33.9 118.3,54.2 104.1,54.2"
                // Translate to origin and scale to fit 18x18
                let scale: CGFloat = 0.44
                let offsetX: CGFloat = -104.1 * scale
                let offsetY: CGFloat = -13.5 * scale

                path.move(to: NSPoint(x: 117.9 * scale + offsetX, y: 33.9 * scale + offsetY))
                path.line(to: NSPoint(x: 104.1 * scale + offsetX, y: 13.5 * scale + offsetY))
                path.line(to: NSPoint(x: 118.3 * scale + offsetX, y: 13.5 * scale + offsetY))
                path.line(to: NSPoint(x: 132.0 * scale + offsetX, y: 33.9 * scale + offsetY))
                path.line(to: NSPoint(x: 118.3 * scale + offsetX, y: 54.2 * scale + offsetY))
                path.line(to: NSPoint(x: 104.1 * scale + offsetX, y: 54.2 * scale + offsetY))
                path.close()
                path.fill()
                return true
            }
            image.isTemplate = true
            button.image = image
            button.action = #selector(toggleSettings)
            button.target = self
        }
    }

    func showOnboarding() {
        let onboardingView = OnboardingView(
            onComplete: { [weak self] serverUrl, token in
                guard let self = self else { return }

                // Close onboarding window first to avoid window server conflicts
                self.onboardingWindow?.close()
                self.onboardingWindow = nil

                // Small delay to ensure window cleanup completes before activation policy change
                // This prevents potential window server errors when transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Change to accessory mode (menu bar only)
                    NSApp.setActivationPolicy(.accessory)

                    // Show main widget directly instead of terminating
                    self.showMainWidget()
                }
            },
            onClose: { [weak self] in
                guard let self = self else { return }
                // User closed onboarding without completing setup
                self.onboardingWindow?.close()
                self.onboardingWindow = nil

                // Ensure we're in a clean state before terminating
                // This avoids EXC_BAD_ACCESS crashes during autorelease pool cleanup
                DispatchQueue.main.async {
                    // Let the current run loop complete to finish window cleanup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        )

        // Center onboarding window
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowWidth: CGFloat = 520
        let windowHeight: CGFloat = 600
        let xPosition = (screenFrame.width - windowWidth) / 2
        let yPosition = (screenFrame.height - windowHeight) / 2

        onboardingWindow = KeyableWindow(
            contentRect: NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        onboardingWindow?.isOpaque = false
        onboardingWindow?.backgroundColor = .clear
        onboardingWindow?.level = .floating
        onboardingWindow?.isMovableByWindowBackground = true

        // CRITICAL FIX: Create NSHostingView in an autoreleasepool to prevent memory corruption
        // during view initialization. This prevents EXC_BAD_ACCESS crashes in objc_autoreleasePoolPop.
        // The issue occurs when NSHostingView's internal autorelease pool cleanup collides with
        // SwiftUI's async task execution during onboarding validation.
        let hostingView = autoreleasepool { () -> NSHostingView<OnboardingView> in
            NSHostingView(rootView: onboardingView)
        }
        onboardingWindow?.contentView = hostingView
        onboardingWindow?.makeKeyAndOrderFront(nil)

        // Ensure window can accept keyboard input in borderless mode
        NSApp.activate(ignoringOtherApps: true)
    }

    func showMainWidget() {
        // Create the floating window
        // Card width: 477px + 75px for album art sticking out left = 552px total + 40px padding
        let screenWidth = NSScreen.main?.frame.width ?? 1920
        let windowWidth: CGFloat = 592  // 552 + 40 for padding
        let windowHeight: CGFloat = 232  // 192 + 40 for padding
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
        let contentView = ContentView(settings: settings)
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        // Prevent window from appearing in Mission Control
        window.collectionBehavior.insert(.transient)
    }

    @objc func toggleSettings() {
        if let settingsWindow = settingsWindow, settingsWindow.isVisible {
            settingsWindow.orderOut(nil)
            self.settingsWindow = nil
            // Clean up monitor
            if let monitor = clickOutsideMonitor {
                NSEvent.removeMonitor(monitor)
                clickOutsideMonitor = nil
            }
        } else {
            showSettings()
        }
    }

    func showSettings() {
        guard let button = statusBarItem?.button else { return }

        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let settingsWidth: CGFloat = 280
        let settingsHeight: CGFloat = 350

        // Position below menu bar icon - left-aligned with no gap
        let xPosition = buttonFrame.minX
        let yPosition = buttonFrame.minY - settingsHeight

        settingsWindow = NSWindow(
            contentRect: NSRect(x: xPosition, y: yPosition, width: settingsWidth, height: settingsHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        settingsWindow?.isOpaque = false
        settingsWindow?.backgroundColor = .clear
        settingsWindow?.level = .floating
        settingsWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let settingsView = SettingsView(settings: settings)
        settingsWindow?.contentView = NSHostingView(rootView: settingsView)
        settingsWindow?.makeKeyAndOrderFront(nil)

        // Remove any existing monitor
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }

        // Close settings when clicking outside - use global monitor to catch all clicks
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let settingsWindow = self.settingsWindow,
                  settingsWindow.isVisible else {
                return
            }

            // Get click location in screen coordinates
            let clickLocation = NSEvent.mouseLocation

            // Get menu button frame if available
            let buttonFrame = self.statusBarItem?.button?.window?.convertToScreen(self.statusBarItem?.button?.frame ?? .zero) ?? .zero

            // Check if click is outside both settings window and menu button
            if !settingsWindow.frame.contains(clickLocation) && !buttonFrame.contains(clickLocation) {
                self.settingsWindow?.orderOut(nil)
                self.settingsWindow = nil
                if let monitor = self.clickOutsideMonitor {
                    NSEvent.removeMonitor(monitor)
                    self.clickOutsideMonitor = nil
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
