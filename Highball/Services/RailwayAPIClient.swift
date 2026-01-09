import Foundation

enum RailwayAPIError: LocalizedError, Equatable {
    case invalidToken
    case rateLimited
    case networkError(String)
    case graphQLErrors([String])
    case decodingError(String)
    case noData

    static func == (lhs: RailwayAPIError, rhs: RailwayAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidToken, .invalidToken),
             (.rateLimited, .rateLimited),
             (.noData, .noData):
            return true
        case (.networkError(let l), .networkError(let r)):
            return l == r
        case (.graphQLErrors(let l), .graphQLErrors(let r)):
            return l == r
        case (.decodingError(let l), .decodingError(let r)):
            return l == r
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid or expired API token"
        case .rateLimited:
            return "Rate limited by Railway. Waiting..."
        case .networkError(let message):
            return "Network error: \(message)"
        case .graphQLErrors(let errors):
            return errors.joined(separator: ", ")
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        case .noData:
            return "No data returned from API"
        }
    }
}

enum TokenType {
    case personal  // Uses Authorization: Bearer
    case project   // Uses Project-Access-Token
}

actor RailwayAPIClient {
    private let baseURL = URL(string: "https://backboard.railway.com/graphql/v2")!
    private var token: String
    private var tokenType: TokenType

    init(token: String) {
        self.token = token
        // Project tokens are UUIDs (36 chars with dashes)
        // Personal tokens typically start with different patterns
        self.tokenType = Self.detectTokenType(token)
    }

    private static func detectTokenType(_ token: String) -> TokenType {
        // Railway now uses UUIDs for both personal and project tokens
        // Default to personal token (more capable) - will fall back if needed
        return .personal
    }

    func updateToken(_ newToken: String) {
        self.token = newToken
        self.tokenType = Self.detectTokenType(newToken)
    }

    // MARK: - GraphQL Queries

    // Query user's projects directly (works with account/workspace tokens)
    private static let projectsQuery = """
    query Projects {
      projects {
        edges {
          node {
            id
            name
            services {
              edges {
                node {
                  id
                  name
                }
              }
            }
            environments {
              edges {
                node {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }
    """

    // For project tokens - get project info from token
    private static let projectTokenQuery = """
    query ProjectToken {
      projectToken {
        projectId
        environmentId
      }
    }
    """

    // Get project details by ID
    private static let projectByIdQuery = """
    query Project($id: String!) {
      project(id: $id) {
        id
        name
        services {
          edges {
            node {
              id
              name
            }
          }
        }
        environments {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    }
    """

    private static let serviceDeploymentsQuery = """
    query ServiceDeployments($serviceId: String!) {
      service(id: $serviceId) {
        deployments(first: 1) {
          edges {
            node {
              id
              status
              createdAt
            }
          }
        }
      }
    }
    """

    private static let environmentDeploymentsQuery = """
    query EnvironmentDeployments($environmentId: String!) {
      environment(id: $environmentId) {
        serviceInstances {
          edges {
            node {
              serviceId
              latestDeployment {
                id
                status
                createdAt
              }
              activeDeployments {
                id
                status
                createdAt
              }
            }
          }
        }
      }
    }
    """

    // MARK: - GraphQL Mutations

    private static let deploymentRestartMutation = """
    mutation DeploymentRestart($id: String!) {
      deploymentRestart(id: $id)
    }
    """

    private static let deploymentRedeployMutation = """
    mutation DeploymentRedeploy($id: String!) {
      deploymentRedeploy(id: $id) {
        id
        status
      }
    }
    """

    // MARK: - Public Methods

    func fetchProjects() async throws -> [Project] {
        switch tokenType {
        case .personal:
            return try await fetchProjectsWithPersonalToken()
        case .project:
            return try await fetchProjectsWithProjectToken()
        }
    }

    private func fetchProjectsWithPersonalToken() async throws -> [Project] {
        let response: GraphQLResponse<ProjectsData> = try await execute(
            query: Self.projectsQuery,
            variables: nil,
            queryName: "Projects"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }

        guard let data = response.data else {
            throw RailwayAPIError.noData
        }

        return data.projects.edges.map(\.node)
    }

    private func fetchProjectsWithProjectToken() async throws -> [Project] {
        // First get the project ID from the token
        let tokenResponse: GraphQLResponse<ProjectTokenData> = try await execute(
            query: Self.projectTokenQuery,
            variables: nil,
            queryName: "ProjectToken"
        )

        if let errors = tokenResponse.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }

        guard let projectId = tokenResponse.data?.projectToken.projectId else {
            throw RailwayAPIError.noData
        }

        // Then fetch the project details
        let projectResponse: GraphQLResponse<ProjectByIdData> = try await execute(
            query: Self.projectByIdQuery,
            variables: ["id": projectId],
            queryName: "Project"
        )

        if let errors = projectResponse.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }

        guard let project = projectResponse.data?.project else {
            throw RailwayAPIError.noData
        }

        return [project]
    }

    func fetchProject(projectId: String) async throws -> Project? {
        let response: GraphQLResponse<ProjectByIdData> = try await execute(
            query: Self.projectByIdQuery,
            variables: ["id": projectId],
            queryName: "Project"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }

        return response.data?.project
    }

    func fetchServiceDeployment(serviceId: String, environmentId: String? = nil) async throws -> Deployment? {
        // If environmentId is provided, query through environment to get correct deployment
        if let environmentId = environmentId {
            let variables: [String: Any] = ["environmentId": environmentId]

            let response: GraphQLResponse<EnvironmentData> = try await execute(
                query: Self.environmentDeploymentsQuery,
                variables: variables,
                queryName: "EnvironmentDeployments"
            )

            if let errors = response.errors, !errors.isEmpty {
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }

            // Find the service instance matching this serviceId
            let serviceInstance = response.data?.environment?.serviceInstances.edges
                .map(\.node)
                .first(where: { $0.serviceId == serviceId })

            // Return active deployment if running, otherwise latest
            if let activeDeployment = serviceInstance?.activeDeployment {
                return activeDeployment
            }

            return serviceInstance?.latestDeployment
        }

        // Fallback to old query if no environmentId (backward compatibility)
        let variables: [String: Any] = ["serviceId": serviceId]

        let response: GraphQLResponse<ServiceDeploymentsData> = try await execute(
            query: Self.serviceDeploymentsQuery,
            variables: variables,
            queryName: "ServiceDeployments"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }

        return response.data?.service?.deployments.edges.first?.node
    }

    func validateToken() async throws -> Bool {
        do {
            _ = try await fetchProjects()
            return true
        } catch RailwayAPIError.graphQLErrors {
            return false
        } catch {
            throw error
        }
    }


    /// Restart a deployment (keeps the same build, just restarts the container)
    func restartDeployment(deploymentId: String) async throws {
        let variables: [String: Any] = ["id": deploymentId]

        let response: GraphQLResponse<DeploymentRestartData> = try await execute(
            query: Self.deploymentRestartMutation,
            variables: variables,
            queryName: "DeploymentRestart"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }
    }

    /// Redeploy a deployment (triggers a new build and deploy)
    func redeployDeployment(deploymentId: String) async throws {
        let variables: [String: Any] = ["id": deploymentId]

        let response: GraphQLResponse<DeploymentRedeployData> = try await execute(
            query: Self.deploymentRedeployMutation,
            variables: variables,
            queryName: "DeploymentRedeploy"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors.map(\.message))
        }
    }

    // MARK: - Private Methods

    private func execute<T: Decodable>(
        query: String,
        variables: [String: Any]?,
        queryName: String
    ) async throws -> T {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "query", value: queryName)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set auth header based on token type
        switch tokenType {
        case .personal:
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .project:
            request.setValue(token, forHTTPHeaderField: "Project-Access-Token")
        }

        var body: [String: Any] = ["query": query]
        if let variables {
            body["variables"] = variables
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                throw RailwayAPIError.invalidToken
            case 429:
                throw RailwayAPIError.rateLimited
            default:
                break
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw RailwayAPIError.decodingError(error.localizedDescription)
        }
    }
}
