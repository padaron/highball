import SwiftUI

struct MenuBarIcon: View {
    let status: DeploymentStatus
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            if status.isBuilding {
                // Purple circle with hammer
                Image(systemName: "hammer.circle.fill")
                    .foregroundStyle(status.outlineColor, status.color)
                    .font(.system(size: 16))
            } else if status.isDeploying {
                // Blue circle with ellipsis
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundStyle(status.outlineColor, status.color)
                    .font(.system(size: 16))
            } else if status.isFailed {
                // Red exclamation circle for failures
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(status.color)
            } else if status.isHealthy {
                // Green circle with up arrow
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.white, status.color)
                    .font(.system(size: 16))
            } else {
                // Gray outline for unknown/offline
                Circle()
                    .stroke(status.color, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 18, height: 18)
    }
}
