import Foundation

enum RailwayAPIError: LocalizedError {
    case invalidToken
    case networkError(Error)
    case graphQLErrors([GraphQLError])
    case decodingError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid or expired API token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .graphQLErrors(let errors):
            return errors.map(\.message).joined(separator: ", ")
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
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
    query ServiceDeployments($serviceId: String!, $environmentId: String) {
      deployments(
        first: 1
        input: { serviceId: $serviceId, environmentId: $environmentId }
      ) {
        edges {
          node {
            id
            status
            createdAt
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
            throw RailwayAPIError.graphQLErrors(errors)
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
            throw RailwayAPIError.graphQLErrors(errors)
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
            throw RailwayAPIError.graphQLErrors(errors)
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
            throw RailwayAPIError.graphQLErrors(errors)
        }

        return response.data?.project
    }

    func fetchServiceDeployment(serviceId: String, environmentId: String?) async throws -> Deployment? {
        var variables: [String: Any] = ["serviceId": serviceId]
        if let environmentId {
            variables["environmentId"] = environmentId
        }

        let response: GraphQLResponse<DeploymentsData> = try await execute(
            query: Self.serviceDeploymentsQuery,
            variables: variables,
            queryName: "ServiceDeployments"
        )

        if let errors = response.errors, !errors.isEmpty {
            throw RailwayAPIError.graphQLErrors(errors)
        }

        return response.data?.deployments.edges.first?.node
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
            throw RailwayAPIError.graphQLErrors(errors)
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
            throw RailwayAPIError.graphQLErrors(errors)
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
            if httpResponse.statusCode == 401 {
                throw RailwayAPIError.invalidToken
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw RailwayAPIError.decodingError(error)
        }
    }
}
