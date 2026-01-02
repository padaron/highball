import SwiftUI

struct StatusDropdownView: View {
    @ObservedObject var monitor: StatusMonitor
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(monitor.displayProjectName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if monitor.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Services list
            if monitor.services.isEmpty && !monitor.isConfigured {
                VStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Not configured")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Open Settings to add your Railway token")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if monitor.services.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading services...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(monitor.services) { service in
                    ServiceRowView(service: service)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = service.railwayURL {
                                openURL(url)
                            }
                        }
                        .contextMenu {
                            Button {
                                Task {
                                    try? await monitor.restartService(service)
                                }
                            } label: {
                                Label("Restart", systemImage: "arrow.clockwise")
                            }

                            Button {
                                Task {
                                    try? await monitor.redeployService(service)
                                }
                            } label: {
                                Label("Redeploy", systemImage: "hammer")
                            }

                            Divider()

                            Button {
                                if let url = service.railwayURL {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                Label("View in Railway", systemImage: "safari")
                            }

                            if let deploymentId = service.deploymentId {
                                Button {
                                    let logsURL = URL(string: "https://railway.com/project/\(service.projectId)/service/\(service.id)/deployment/\(deploymentId)?tab=logs")!
                                    NSWorkspace.shared.open(logsURL)
                                } label: {
                                    Label("View Logs", systemImage: "doc.text")
                                }
                            }
                        }
                }
            }

            // Error message
            if let error = monitor.lastError {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // History section
            if !monitor.history.isEmpty {
                Divider()
                HStack {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 2)

                ForEach(monitor.history.prefix(10)) { entry in
                    HistoryRowView(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = entry.railwayURL {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }
            }

            Divider()

            // Actions
            VStack(spacing: 0) {
                Button {
                    Task {
                        await monitor.refresh()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Now")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())

                Button {
                    openSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings...")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Highball")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
        }
        .frame(width: 260)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}

struct HistoryRowView: View {
    let entry: DeploymentHistoryEntry

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(entry.newStatus.color)
                .frame(width: 6, height: 6)

            Text(entry.serviceName)
                .font(.caption)
                .lineLimit(1)

            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)

            Text(entry.newStatus.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let duration = entry.deploymentDuration {
                Text("(\(duration))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(entry.formattedTime)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}
