import Foundation

// MARK: - GraphQL Response Wrappers

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
    let path: [String]?
}

// MARK: - Projects Query Response

struct ProjectsData: Decodable {
    let projects: ProjectConnection
}

struct ProjectConnection: Decodable {
    let edges: [ProjectEdge]
}

struct ProjectEdge: Decodable {
    let node: Project
}

struct Project: Decodable, Identifiable {
    let id: String
    let name: String
    let services: ServiceConnection
}

struct ServiceConnection: Decodable {
    let edges: [ServiceEdge]
}

struct ServiceEdge: Decodable {
    let node: Service
}

struct Service: Decodable, Identifiable {
    let id: String
    let name: String
}

// MARK: - Project Token Query Response

struct ProjectTokenData: Decodable {
    let projectToken: ProjectTokenInfo
}

struct ProjectTokenInfo: Decodable {
    let projectId: String
    let environmentId: String
}

// MARK: - Project By ID Query Response

struct ProjectByIdData: Decodable {
    let project: Project
}

// MARK: - Deployments Query Response

struct ServiceDeploymentsData: Decodable {
    let service: ServiceWithDeployments?
}

struct ServiceWithDeployments: Decodable {
    let deployments: DeploymentConnection
}

struct DeploymentConnection: Decodable {
    let edges: [DeploymentEdge]
}

struct DeploymentEdge: Decodable {
    let node: Deployment
}

struct Deployment: Decodable, Identifiable {
    let id: String
    let status: DeploymentStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(DeploymentStatus.self, forKey: .status)

        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            createdAt = formatter.date(from: dateString) ?? Date()
        }
    }
}

// MARK: - Environment Status Query Response

struct EnvironmentData: Decodable {
    let environment: EnvironmentInfo?
}

struct EnvironmentInfo: Decodable {
    let serviceInstances: ServiceInstanceConnection
}

struct ServiceInstanceConnection: Decodable {
    let edges: [ServiceInstanceEdge]
}

struct ServiceInstanceEdge: Decodable {
    let node: ServiceInstance
}

struct ServiceInstance: Decodable {
    let serviceId: String
    let latestDeployment: Deployment?
}
