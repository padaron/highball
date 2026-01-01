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
    private let pollingInterval: TimeInterval = 5.0

    private var projectId: String?
    private var serviceIds: [String] = []

    // Track previous statuses for notification diffing
    private var previousStatuses: [String: DeploymentStatus] = [:]

    // MARK: - Initialization

    init() {
        loadConfiguration()
    }

    // MARK: - Public Methods

    func configure(token: String, projectId: String, serviceIds: [String]) async {
        // Save token to Keychain
        try? KeychainManager.saveToken(token)

        self.apiClient = RailwayAPIClient(token: token)
        self.projectId = projectId
        self.serviceIds = serviceIds
        self.isConfigured = true

        saveConfiguration()
        await refresh()
        startPolling()
    }

    func refresh() async {
        guard let apiClient, !serviceIds.isEmpty else { return }

        isLoading = true
        lastError = nil

        do {
            var updatedServices: [MonitoredService] = []

            for serviceId in serviceIds {
                if let deployment = try await apiClient.fetchServiceDeployment(serviceId: serviceId) {
                    let existingService = services.first(where: { $0.id == serviceId })

                    let service = MonitoredService(
                        id: serviceId,
                        projectId: projectId ?? "",
                        projectName: "Cratewise",
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
                    }
                    previousStatuses[serviceId] = deployment.status
                }
            }

            self.services = updatedServices
        } catch {
            self.lastError = error.localizedDescription
        }

        isLoading = false
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

    func reset() {
        stop()
        try? KeychainManager.deleteToken()
        UserDefaults.standard.removeObject(forKey: "projectId")
        UserDefaults.standard.removeObject(forKey: "serviceIds")
        UserDefaults.standard.removeObject(forKey: "serviceNames")
        services = []
        isConfigured = false
        previousStatuses = [:]
    }

    // MARK: - Private Methods

    private func startPolling() {
        pollingTimer?.cancel()

        pollingTimer = Timer.publish(every: pollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh()
                }
            }
    }

    private func loadConfiguration() {
        let defaults = UserDefaults.standard

        if let projectId = defaults.string(forKey: "projectId"),
           let serviceIds = defaults.stringArray(forKey: "serviceIds"),
           let token = KeychainManager.getToken() {
            self.projectId = projectId
            self.serviceIds = serviceIds
            self.apiClient = RailwayAPIClient(token: token)
            self.isConfigured = true

            if let serviceNames = defaults.dictionary(forKey: "serviceNames") as? [String: String] {
                self.services = serviceIds.map { id in
                    MonitoredService(
                        id: id,
                        projectId: projectId,
                        projectName: "Cratewise",
                        serviceName: serviceNames[id] ?? id,
                        status: .unknown,
                        lastUpdated: Date(),
                        deploymentStartedAt: nil,
                        deploymentId: nil
                    )
                }
            }

            Task {
                await refresh()
                startPolling()
            }
        }
    }

    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(projectId, forKey: "projectId")
        defaults.set(serviceIds, forKey: "serviceIds")

        let serviceNames = Dictionary(uniqueKeysWithValues: services.map { ($0.id, $0.serviceName) })
        defaults.set(serviceNames, forKey: "serviceNames")
    }
}
