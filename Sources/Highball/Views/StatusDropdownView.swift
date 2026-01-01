import SwiftUI

struct StatusDropdownView: View {
    @ObservedObject var monitor: StatusMonitor
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Cratewise")
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
