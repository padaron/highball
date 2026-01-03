import Foundation
import SwiftUI
import Combine

@MainActor
final class StatusMonitor: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var services: [MonitoredService] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published private(set) var isConfigured = false
    @Published private(set) var history: [DeploymentHistoryEntry] = []

    var displayProjectName: String {
        projectName ?? "Project"
    }

    private let maxHistoryEntries = 20

    // MARK: - Computed Properties

    var aggregateStatus: DeploymentStatus {
        guard !services.isEmpty else { return .unknown }
        return services.min(by: { $0.status.priority < $1.status.priority })?.status ?? .unknown
    }

    var menuBarIcon: String {
        switch aggregateStatus {
        case .success:
            return "circle.fill"
        case .building, .deploying, .initializing, .waiting:
            return "circle.dotted"
        case .failed, .crashed:
            return "exclamationmark.circle.fill"
        default:
            return "circle"
        }
    }

    var menuBarColor: Color {
        aggregateStatus.color
    }

    // MARK: - Private Properties

    private var apiClient: RailwayAPIClient?
    private var pollingTimer: AnyCancellable?
    private let basePollingInterval: TimeInterval = 30.0  // Increased to avoid rate limits
    private var currentPollingInterval: TimeInterval = 30.0
    private var consecutiveRateLimits = 0

    private var projectId: String?
    private var projectName: String?
    private var environmentId: String?
    private var serviceIds: [String] = []
    private var hasAttemptedEnvMigration = false

    // Track previous statuses for notification diffing
    private var previousStatuses: [String: DeploymentStatus] = [:]

    // MARK: - Initialization

    init() {
        loadConfiguration()
        loadHistory()
    }

    // MARK: - Public Methods

    func configure(token: String, projectId: String, projectName: String, environmentId: String?, serviceIds: [String]) async {
        // Save token to Keychain
        try? KeychainManager.saveToken(token)

        self.apiClient = RailwayAPIClient(token: token)
        self.projectId = projectId
        self.projectName = projectName
        self.environmentId = environmentId
        self.serviceIds = serviceIds
        self.isConfigured = true

        saveConfiguration()
        await refresh(showLoading: true)
        startPolling()
    }

    func refresh(showLoading: Bool = false) async {
        guard let apiClient, !serviceIds.isEmpty else { return }

        // Auto-migrate: fetch environmentId if we don't have one (only try once)
        if environmentId == nil, !hasAttemptedEnvMigration, let projectId {
            hasAttemptedEnvMigration = true
            do {
                if let project = try await apiClient.fetchProject(projectId: projectId) {
                    self.environmentId = project.productionEnvironmentId
                    saveConfiguration()
                }
            } catch {
                // Continue without environment filtering if fetch fails
            }
        }

        // Only show loading indicator for manual refreshes, not background polling
        if showLoading {
            isLoading = true
        }

        var updatedServices: [MonitoredService] = []
        var fetchError: String?

        var hitRateLimit = false

        for serviceId in serviceIds {
            do {
                if let deployment = try await apiClient.fetchServiceDeployment(serviceId: serviceId) {
                    let existingService = services.first(where: { $0.id == serviceId })

                    let service = MonitoredService(
                        id: serviceId,
                        projectId: projectId ?? "",
                        projectName: projectName ?? "Project",
                        serviceName: existingService?.serviceName ?? serviceId,
                        status: deployment.status,
                        lastUpdated: Date(),
                        deploymentStartedAt: deployment.createdAt,
                        deploymentId: deployment.id
                    )
                    updatedServices.append(service)

                    // Check for status changes and send notifications
                    let oldStatus = previousStatuses[serviceId]
                    if let old = oldStatus, old != deployment.status {
                        NotificationManager.shared.notifyStatusChange(
                            service: service,
                            oldStatus: old,
                            newStatus: deployment.status
                        )
                        // Record to history
                        let entry = DeploymentHistoryEntry(
                            serviceId: serviceId,
                            serviceName: service.serviceName,
                            projectId: projectId ?? "",
                            deploymentId: deployment.id,
                            oldStatus: old,
                            newStatus: deployment.status,
                            deploymentCreatedAt: deployment.createdAt
                        )
                        history.insert(entry, at: 0)
                        if history.count > maxHistoryEntries {
                            history = Array(history.prefix(maxHistoryEntries))
                        }
                        saveHistory()
                    }
                    previousStatuses[serviceId] = deployment.status
                }
            } catch let error as RailwayAPIError where error == .rateLimited {
                hitRateLimit = true
                fetchError = error.localizedDescription
                break  // Stop making more requests if rate limited
            } catch {
                fetchError = error.localizedDescription
            }
        }

        // Handle rate limit backoff
        if hitRateLimit {
            handleRateLimit()
        } else {
            resetRateLimitBackoff()
        }

        // Only update if changed to avoid unnecessary SwiftUI re-renders
        if !servicesEqual(services, updatedServices) {
            self.services = updatedServices
        }
        if self.lastError != fetchError {
            self.lastError = fetchError
        }
        if showLoading {
            isLoading = false
        }
    }

    private func servicesEqual(_ lhs: [MonitoredService], _ rhs: [MonitoredService]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for (l, r) in zip(lhs, rhs) {
            if l.id != r.id || l.status != r.status || l.deploymentId != r.deploymentId {
                return false
            }
        }
        return true
    }

    func discoverServices(token: String) async throws -> [(project: Project, services: [Service])] {
        let client = RailwayAPIClient(token: token)
        let projects = try await client.fetchProjects()

        return projects.map { project in
            (project: project, services: project.services.edges.map(\.node))
        }
    }

    func setServiceNames(_ names: [String: String]) {
        services = services.map { service in
            var updated = service
            if let name = names[service.id] {
                updated = MonitoredService(
                    id: service.id,
                    projectId: service.projectId,
                    projectName: service.projectName,
                    serviceName: name,
                    status: service.status,
                    lastUpdated: service.lastUpdated,
                    deploymentStartedAt: service.deploymentStartedAt,
                    deploymentId: service.deploymentId
                )
            }
            return updated
        }
        saveConfiguration()
    }

    func stop() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    /// Restart a service's current deployment (keeps same build)
    func restartService(_ service: MonitoredService) async throws {
        guard let apiClient, let deploymentId = service.deploymentId else { return }
        try await apiClient.restartDeployment(deploymentId: deploymentId)
        // Refresh to get updated status
        await refresh(showLoading: true)
    }

    /// Redeploy a service (triggers new build)
    func redeployService(_ service: MonitoredService) async throws {
        guard let apiClient, let deploymentId = service.deploymentId else { return }
        try await apiClient.redeployDeployment(deploymentId: deploymentId)
        // Refresh to get updated status
        await refresh(showLoading: true)
    }

    func reset() {
        stop()
        try? KeychainManager.deleteToken()
        UserDefaults.standard.removeObject(forKey: "projectId")
        UserDefaults.standard.removeObject(forKey: "environmentId")
        UserDefaults.standard.removeObject(forKey: "serviceIds")
        UserDefaults.standard.removeObject(forKey: "serviceNames")
        UserDefaults.standard.removeObject(forKey: "deploymentHistory")
        services = []
        history = []
        isConfigured = false
        previousStatuses = [:]
    }

    // MARK: - Private Methods

    private func startPolling() {
        pollingTimer?.cancel()

        pollingTimer = Timer.publish(every: currentPollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh()
                }
            }
    }

    private func handleRateLimit() {
        consecutiveRateLimits += 1
        // Exponential backoff: 30s -> 60s -> 120s -> max 5min
        currentPollingInterval = min(basePollingInterval * pow(2.0, Double(consecutiveRateLimits - 1)), 300.0)
        startPolling() // Restart with new interval
    }

    private func resetRateLimitBackoff() {
        if consecutiveRateLimits > 0 {
            consecutiveRateLimits = 0
            currentPollingInterval = basePollingInterval
            startPolling() // Restart with normal interval
        }
    }

    private func loadConfiguration() {
        let defaults = UserDefaults.standard

        if let projectId = defaults.string(forKey: "projectId"),
           let serviceIds = defaults.stringArray(forKey: "serviceIds"),
           let token = KeychainManager.getToken() {
            self.projectId = projectId
            self.projectName = defaults.string(forKey: "projectName")
            self.environmentId = defaults.string(forKey: "environmentId")
            self.serviceIds = serviceIds
            self.apiClient = RailwayAPIClient(token: token)
            self.isConfigured = true

            if let serviceNames = defaults.dictionary(forKey: "serviceNames") as? [String: String] {
                let name = self.projectName ?? "Project"
                self.services = serviceIds.map { id in
                    MonitoredService(
                        id: id,
                        projectId: projectId,
                        projectName: name,
                        serviceName: serviceNames[id] ?? id,
                        status: .unknown,
                        lastUpdated: Date(),
                        deploymentStartedAt: nil,
                        deploymentId: nil
                    )
                }
            }

            Task {
                await refresh(showLoading: true)
                startPolling()
            }
        }
    }

    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(projectId, forKey: "projectId")
        defaults.set(projectName, forKey: "projectName")
        defaults.set(environmentId, forKey: "environmentId")
        defaults.set(serviceIds, forKey: "serviceIds")

        let serviceNames = Dictionary(uniqueKeysWithValues: services.map { ($0.id, $0.serviceName) })
        defaults.set(serviceNames, forKey: "serviceNames")
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "deploymentHistory"),
              let entries = try? JSONDecoder().decode([DeploymentHistoryEntry].self, from: data) else {
            return
        }
        history = entries
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: "deploymentHistory")
    }
}
