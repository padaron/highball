import SwiftUI
import UserNotifications

@main
struct HighballApp: App {
    @StateObject private var statusMonitor = StatusMonitor()
    @StateObject private var hotKeyManager = HotKeyManager.shared

    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        MenuBarExtra {
            StatusDropdownView(monitor: statusMonitor)
                .onAppear {
                    hotKeyManager.statusMonitor = statusMonitor
                }
        } label: {
            MenuBarIcon(status: statusMonitor.aggregateStatus)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("Highball Settings", id: "settings") {
            SettingsView(monitor: statusMonitor)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Onboarding window for first-time setup
        Window("Welcome to Highball", id: "onboarding") {
            OnboardingView(monitor: statusMonitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
