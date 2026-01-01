import SwiftUI

struct ServiceRowView: View {
    let service: MonitoredService

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            StatusDot(status: service.status)

            // Service name
            Text(service.serviceName)
                .font(.system(.body, design: .default))
                .foregroundStyle(.primary)

            Spacer()

            // Status text and time
            HStack(spacing: 4) {
                Text(service.status.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let time = service.timeInCurrentState, service.status.isInProgress {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            // Chevron for clickability hint
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

struct StatusDot: View {
    let status: DeploymentStatus
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            if status.isBuilding {
                // Purple circle with hammer
                Circle()
                    .fill(status.color)
                    .frame(width: 10, height: 10)

                Image(systemName: "hammer.fill")
                    .font(.system(size: 5, weight: .bold))
                    .foregroundStyle(status.outlineColor)

                Circle()
                    .stroke(
                        status.outlineColor,
                        style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                    )
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else if status.isDeploying {
                // Blue circle with ellipsis
                Circle()
                    .fill(status.color)
                    .frame(width: 10, height: 10)

                Image(systemName: "ellipsis")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(status.outlineColor)

                Circle()
                    .stroke(
                        status.outlineColor,
                        style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                    )
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else {
                // Simple filled circle for other states
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 16, height: 16)
    }
}

#Preview {
    VStack(spacing: 0) {
        ServiceRowView(service: MonitoredService(
            id: "1",
            projectId: "proj1",
            projectName: "Cratewise",
            serviceName: "Frontend",
            status: .success,
            lastUpdated: Date(),
            deploymentStartedAt: nil,
            deploymentId: nil
        ))

        Divider()

        ServiceRowView(service: MonitoredService(
            id: "2",
            projectId: "proj1",
            projectName: "Cratewise",
            serviceName: "Backend",
            status: .deploying,
            lastUpdated: Date(),
            deploymentStartedAt: Date().addingTimeInterval(-125),
            deploymentId: nil
        ))

        Divider()

        ServiceRowView(service: MonitoredService(
            id: "3",
            projectId: "proj1",
            projectName: "Cratewise",
            serviceName: "Database",
            status: .failed,
            lastUpdated: Date(),
            deploymentStartedAt: nil,
            deploymentId: nil
        ))
    }
    .frame(width: 260)
}
