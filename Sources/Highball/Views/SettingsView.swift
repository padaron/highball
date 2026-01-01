import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: StatusMonitor
    @ObservedObject var notifications = NotificationManager.shared
    @ObservedObject var launchAtLogin = LaunchAtLoginManager.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    @State private var selectedTab = "general"
    @State private var tokenInput = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var showResetConfirmation = false

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")

            notificationsTab
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag("notifications")

            connectionTab
                .tabItem {
                    Label("Connection", systemImage: "network")
                }
                .tag("connection")
        }
        .frame(width: 450, height: 320)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)

                HStack {
                    Text("Polling Interval")
                    Spacer()
                    Text("5 seconds")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if monitor.isConfigured {
                    ForEach(monitor.services) { service in
                        HStack {
                            Circle()
                                .fill(service.status.color)
                                .frame(width: 8, height: 8)
                            Text(service.serviceName)
                            Spacer()
                            Text(service.status.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Not configured")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Set Up") {
                            openOnboarding()
                        }
                    }
                }
            } header: {
                Text("Monitored Services")
            }

            Section {
                Link("Railway Dashboard", destination: URL(string: "https://railway.com/dashboard")!)
                Link("Railway API Tokens", destination: URL(string: "https://railway.com/account/tokens")!)
            } header: {
                Text("Quick Links")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Notifications Tab

    private var notificationsTab: some View {
        Form {
            Section {
                if notifications.isAuthorized {
                    Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    HStack {
                        Label("Notifications disabled", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        Button("Enable") {
                            Task {
                                await notifications.requestAuthorization()
                            }
                        }
                    }
                }
            }

            Section {
                Toggle("Build started", isOn: $notifications.notifyOnBuilding)
                Toggle("Deploying", isOn: $notifications.notifyOnDeploying)
                Toggle("Deploy succeeded", isOn: $notifications.notifyOnSuccess)
                Toggle("Deploy failed", isOn: $notifications.notifyOnFailure)
            } header: {
                Text("Notify me when")
            }

            Section {
                Toggle("Play sound on failure", isOn: $notifications.playSoundOnFailure)
            } header: {
                Text("Sound")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Connection Tab

    private var connectionTab: some View {
        Form {
            Section {
                if monitor.isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Railway")
                    }

                    HStack {
                        Text("Token")
                        Spacer()
                        Text("••••••••")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Not connected")
                    }
                }
            } header: {
                Text("Status")
            }

            if !monitor.isConfigured {
                Section {
                    SecureField("Railway API Token", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Get Token") {
                            openURL(URL(string: "https://railway.com/account/tokens")!)
                        }

                        Spacer()

                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button("Connect") {
                            // For now, open onboarding for full setup
                            openOnboarding()
                        }
                        .disabled(tokenInput.isEmpty || isValidating)
                    }

                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Connect")
                }
            }

            Section {
                Button("Reset Configuration", role: .destructive) {
                    showResetConfirmation = true
                }
            } footer: {
                Text("This will remove your API token and service configuration.")
            }
        }
        .formStyle(.grouped)
        .alert("Reset Configuration?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                monitor.reset()
            }
        } message: {
            Text("This will remove your API token and you'll need to set up Highball again.")
        }
    }

    private func openOnboarding() {
        openWindow(id: "onboarding")
    }
}
