import Foundation
import SwiftUI

enum DeploymentStatus: String, Codable {
    case success = "SUCCESS"
    case building = "BUILDING"
    case deploying = "DEPLOYING"
    case failed = "FAILED"
    case crashed = "CRASHED"
    case removed = "REMOVED"
    case removing = "REMOVING"
    case initializing = "INITIALIZING"
    case waiting = "WAITING"
    case sleeping = "SLEEPING"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = DeploymentStatus(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .success: "Online"
        case .building: "Building"
        case .deploying: "Deploying"
        case .failed: "Failed"
        case .crashed: "Crashed"
        case .removed: "Removed"
        case .removing: "Removing"
        case .initializing: "Initializing"
        case .waiting: "Waiting"
        case .sleeping: "Sleeping"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .success: .green
        case .building: Color(red: 0.8, green: 0.6, blue: 1.0) // light purple
        case .deploying, .initializing, .waiting: Color(red: 0.4, green: 0.7, blue: 1.0) // light blue
        case .failed, .crashed: .red
        case .removed, .removing, .sleeping: .gray
        case .unknown: .gray
        }
    }

    var outlineColor: Color {
        switch self {
        case .building: Color(red: 0.5, green: 0.2, blue: 0.8) // dark purple
        case .deploying, .initializing, .waiting: Color(red: 0.2, green: 0.4, blue: 0.8) // dark blue
        default: color
        }
    }

    var isBuilding: Bool {
        self == .building
    }

    var isDeploying: Bool {
        switch self {
        case .deploying, .initializing, .waiting:
            return true
        default:
            return false
        }
    }

    var isHealthy: Bool {
        self == .success
    }

    var isInProgress: Bool {
        switch self {
        case .building, .deploying, .initializing, .waiting:
            return true
        default:
            return false
        }
    }

    var isFailed: Bool {
        switch self {
        case .failed, .crashed:
            return true
        default:
            return false
        }
    }

    /// Priority for aggregate status (lower = show first)
    /// Order: failed > building > deploying > success
    var priority: Int {
        switch self {
        case .failed, .crashed: 0      // worst - show first
        case .building: 1               // building before deploying
        case .deploying, .initializing, .waiting: 2
        case .success: 3                // best - show last
        case .sleeping: 4
        case .removed, .removing, .unknown: 5
        }
    }
}

struct MonitoredService: Identifiable {
    let id: String
    let projectId: String
    let projectName: String
    let serviceName: String
    var status: DeploymentStatus
    var lastUpdated: Date
    var deploymentStartedAt: Date?
    var deploymentId: String?

    var railwayURL: URL? {
        URL(string: "https://railway.com/project/\(projectId)/service/\(id)")
    }

    var timeInCurrentState: String? {
        guard let startedAt = deploymentStartedAt else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        let minutes = Int(elapsed / 60)
        let seconds = Int(elapsed.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}
