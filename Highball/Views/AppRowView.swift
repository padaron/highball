import SwiftUI

struct AppRowView: View {
    let app: MonitoredApp
    @ObservedObject var monitor: StatusMonitor
    @Binding var expandedAppId: UUID?
    @Environment(\.openURL) private var openURL

    var isExpanded: Bool {
        expandedAppId == app.id
    }

    var appServices: [MonitoredService] {
        app.getServices(from: monitor.services)
    }

    var appStatus: DeploymentStatus {
        app.aggregateStatus(services: monitor.services)
    }

    var body: some View {
        VStack(spacing: 0) {
            // App header
            HStack(spacing: 10) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                StatusDot(status: appStatus)

                Text(app.name)
                    .font(.system(.body, design: .default, weight: .medium))

                Spacer()

                HStack(spacing: 4) {
                    Text(appStatus.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("(\(app.serviceIds.count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                if isExpanded {
                    expandedAppId = nil
                } else {
                    expandedAppId = app.id
                }
            }
            .contextMenu {
                Button {
                    if let projectId = appServices.first?.projectId,
                       let url = app.railwayURL(projectId: projectId) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("View in Railway", systemImage: "safari")
                }
            }

            // Expanded services (indented)
            if isExpanded {
                ForEach(appServices, id: \.id) { service in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(service.status.color)
                            .frame(width: 8, height: 8)

                        Text(service.serviceName)
                            .font(.body)

                        Spacer()

                        Text(service.status.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
