import Foundation
import SwiftUI

enum DeploymentStatus: String, Codable {
    case success = "SUCCESS"
    case building = "BUILDING"
    case deploying = "DEPLOYING"
    case failed = "FAILED"
    case crashed = "CRASHED"
    case error = "ERROR"
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
        case .error: "Error"
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
        case .error: .orange
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
        case .failed, .crashed, .error:
            return true
        default:
            return false
        }
    }

    /// Priority for aggregate status (lower = show first)
    /// Order: failed > building > deploying > success
    var priority: Int {
        switch self {
        case .failed, .crashed, .error: 0      // worst - show first
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

struct DeploymentHistoryEntry: Identifiable, Codable {
    let id: UUID
    let serviceId: String
    let serviceName: String
    let projectId: String
    let deploymentId: String?
    let oldStatus: DeploymentStatus
    let newStatus: DeploymentStatus
    let timestamp: Date
    let deploymentCreatedAt: Date?

    init(
        serviceId: String,
        serviceName: String,
        projectId: String,
        deploymentId: String?,
        oldStatus: DeploymentStatus,
        newStatus: DeploymentStatus,
        deploymentCreatedAt: Date?
    ) {
        self.id = UUID()
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.projectId = projectId
        self.deploymentId = deploymentId
        self.oldStatus = oldStatus
        self.newStatus = newStatus
        self.timestamp = Date()
        self.deploymentCreatedAt = deploymentCreatedAt
    }

    // Custom decoder to handle legacy entries missing new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        serviceId = try container.decode(String.self, forKey: .serviceId)
        serviceName = try container.decode(String.self, forKey: .serviceName)
        projectId = try container.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        deploymentId = try container.decodeIfPresent(String.self, forKey: .deploymentId)
        oldStatus = try container.decode(DeploymentStatus.self, forKey: .oldStatus)
        newStatus = try container.decode(DeploymentStatus.self, forKey: .newStatus)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        deploymentCreatedAt = try container.decodeIfPresent(Date.self, forKey: .deploymentCreatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, serviceId, serviceName, projectId, deploymentId
        case oldStatus, newStatus, timestamp, deploymentCreatedAt
    }

    var railwayURL: URL? {
        guard let deploymentId = deploymentId else {
            return URL(string: "https://railway.com/project/\(projectId)/service/\(serviceId)")
        }
        return URL(string: "https://railway.com/project/\(projectId)/service/\(serviceId)/deployment/\(deploymentId)")
    }

    var timeAgo: String {
        let elapsed = Date().timeIntervalSince(timestamp)
        let seconds = Int(elapsed)
        let minutes = Int(elapsed / 60)
        let hours = Int(elapsed / 3600)
        let days = Int(elapsed / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else if seconds > 10 {
            return "\(seconds)s ago"
        } else {
            return "just now"
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Yesterday' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }

        return formatter.string(from: timestamp)
    }

    /// Duration from deployment creation to this status change (for terminal states)
    var deploymentDuration: String? {
        guard let createdAt = deploymentCreatedAt else { return nil }
        // Only show duration for terminal states
        guard newStatus == .success || newStatus.isFailed else { return nil }

        let elapsed = timestamp.timeIntervalSince(createdAt)
        let seconds = Int(elapsed)
        let minutes = Int(elapsed / 60)
        let remainingSeconds = seconds % 60

        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct MonitoredApp: Identifiable, Codable {
    let id: UUID
    var name: String
    var serviceIds: [String]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, serviceIds: [String]) {
        self.id = id
        self.name = name
        self.serviceIds = serviceIds
        self.createdAt = Date()
    }
}

extension MonitoredApp {
    /// Calculate aggregate status from services in this app
    func aggregateStatus(services: [MonitoredService]) -> DeploymentStatus {
        let appServices = services.filter { serviceIds.contains($0.id) }
        guard !appServices.isEmpty else { return .unknown }
        return appServices.min(by: { $0.status.priority < $1.status.priority })?.status ?? .unknown
    }

    /// Get services belonging to this app
    func getServices(from allServices: [MonitoredService]) -> [MonitoredService] {
        return allServices.filter { serviceIds.contains($0.id) }
    }

    /// Railway project URL
    func railwayURL(projectId: String) -> URL? {
        URL(string: "https://railway.com/project/\(projectId)")
    }
}
