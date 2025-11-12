import Foundation
import ServiceManagement

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool = false {
        didSet {
            // Only trigger update if this is a user-initiated change
            if !isUpdatingFromSystem {
                setLaunchAtLogin(enabled: isEnabled)
            }
        }
    }

    private var isUpdatingFromSystem = false

    private init() {
        // Don't check status on init to avoid triggering permission prompt
        // Only check when user interacts with the toggle
    }

    func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    // Already enabled
                    return
                }
                try SMAppService.mainApp.register()
                print("✅ Launch at login enabled")
            } else {
                if SMAppService.mainApp.status == .notRegistered {
                    // Already disabled
                    return
                }
                try SMAppService.mainApp.unregister()
                print("✅ Launch at login disabled")
            }
        } catch {
            print("❌ Failed to set launch at login: \(error.localizedDescription)")
            // Revert the published value on failure
            isUpdatingFromSystem = true
            DispatchQueue.main.async { [weak self] in
                self?.isEnabled = !enabled
                self?.isUpdatingFromSystem = false
            }
        }
    }

    func checkStatus() {
        isUpdatingFromSystem = true
        isEnabled = SMAppService.mainApp.status == .enabled
        isUpdatingFromSystem = false
    }
}
