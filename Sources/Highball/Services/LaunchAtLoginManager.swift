import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool {
        didSet {
            if isEnabled != oldValue {
                setLaunchAtLogin(isEnabled)
            }
        }
    }

    private init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
            // Revert the published value if registration failed
            Task { @MainActor in
                self.isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
