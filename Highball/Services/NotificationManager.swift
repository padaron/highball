import Foundation
import UserNotifications
import AppKit

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var isAuthorized = false
    private var successSound: NSSound?
    private var failureSound: NSSound?

    // Notification preferences (stored in UserDefaults)
    @Published var notifyOnSuccess: Bool {
        didSet { UserDefaults.standard.set(notifyOnSuccess, forKey: "notifyOnSuccess") }
    }
    @Published var notifyOnBuilding: Bool {
        didSet { UserDefaults.standard.set(notifyOnBuilding, forKey: "notifyOnBuilding") }
    }
    @Published var notifyOnDeploying: Bool {
        didSet { UserDefaults.standard.set(notifyOnDeploying, forKey: "notifyOnDeploying") }
    }
    @Published var notifyOnFailure: Bool {
        didSet { UserDefaults.standard.set(notifyOnFailure, forKey: "notifyOnFailure") }
    }
    @Published var playSoundOnFailure: Bool {
        didSet { UserDefaults.standard.set(playSoundOnFailure, forKey: "playSoundOnFailure") }
    }
    @Published var playSoundOnSuccess: Bool {
        didSet { UserDefaults.standard.set(playSoundOnSuccess, forKey: "playSoundOnSuccess") }
    }

    private init() {
        // Load preferences with defaults (all enabled except sound)
        let defaults = UserDefaults.standard
        self.notifyOnSuccess = defaults.object(forKey: "notifyOnSuccess") as? Bool ?? true
        self.notifyOnBuilding = defaults.object(forKey: "notifyOnBuilding") as? Bool ?? true
        self.notifyOnDeploying = defaults.object(forKey: "notifyOnDeploying") as? Bool ?? true
        self.notifyOnFailure = defaults.object(forKey: "notifyOnFailure") as? Bool ?? true
        self.playSoundOnFailure = defaults.object(forKey: "playSoundOnFailure") as? Bool ?? false
        self.playSoundOnSuccess = defaults.object(forKey: "playSoundOnSuccess") as? Bool ?? false

        // Load train whistle sound from bundle
        if let soundURL = Bundle.main.url(forResource: "train_whistle", withExtension: "caf") {
            self.successSound = NSSound(contentsOf: soundURL, byReference: true)
        }

        // Load failure sound from bundle
        if let soundURL = Bundle.main.url(forResource: "failure_basso", withExtension: "caf") {
            self.failureSound = NSSound(contentsOf: soundURL, byReference: true)
        }

        Task {
            await checkAuthorization()
        }

        // Re-check authorization when app becomes active (e.g., after returning from System Settings)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAuthorization()
            }
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            print("Notification authorization failed: \(error)")
            isAuthorized = false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func notifyStatusChange(
        service: MonitoredService,
        oldStatus: DeploymentStatus,
        newStatus: DeploymentStatus
    ) {
        guard isAuthorized else { return }
        guard shouldNotify(for: newStatus) else { return }

        let content = UNMutableNotificationContent()
        content.title = statusTitle(for: newStatus, serviceName: service.serviceName)
        content.body = statusBody(for: newStatus, serviceName: service.serviceName)
        content.categoryIdentifier = "STATUS_CHANGE"
        content.userInfo = [
            "serviceId": service.id,
            "projectId": service.projectId,
            "url": service.railwayURL?.absoluteString ?? ""
        ]

        // Play custom failure sound on failed deployment
        if newStatus.isFailed && playSoundOnFailure {
            failureSound?.play()
        }

        // Play train whistle on successful deployment
        if newStatus == .success && playSoundOnSuccess {
            successSound?.play()
        }

        let request = UNNotificationRequest(
            identifier: "\(service.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifyAppStatusChange(
        app: MonitoredApp,
        services: [MonitoredService],
        oldStatus: DeploymentStatus,
        newStatus: DeploymentStatus
    ) {
        guard isAuthorized else { return }
        guard shouldNotify(for: newStatus) else { return }

        let content = UNMutableNotificationContent()
        content.title = statusTitle(for: newStatus, serviceName: app.name)
        content.body = appStatusBody(for: newStatus, serviceCount: services.count)
        content.categoryIdentifier = "APP_STATUS_CHANGE"

        if let firstService = services.first {
            content.userInfo = [
                "appId": app.id.uuidString,
                "projectId": firstService.projectId,
                "url": app.railwayURL(projectId: firstService.projectId)?.absoluteString ?? ""
            ]
        }

        // Play custom failure sound on failed deployment
        if newStatus.isFailed && playSoundOnFailure {
            failureSound?.play()
        }

        // Play train whistle on successful deployment
        if newStatus == .success && playSoundOnSuccess {
            successSound?.play()
        }

        let request = UNNotificationRequest(
            identifier: "\(app.id.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func appStatusBody(for status: DeploymentStatus, serviceCount: Int) -> String {
        let serviceWord = serviceCount == 1 ? "service" : "services"

        switch status {
        case .success:
            return "\(serviceCount) \(serviceWord) deployed successfully"
        case .building:
            return "\(serviceCount) \(serviceWord) building"
        case .deploying:
            return "\(serviceCount) \(serviceWord) deploying"
        case .failed:
            return "\(serviceCount) \(serviceWord) failed"
        case .crashed:
            return "\(serviceCount) \(serviceWord) crashed"
        default:
            return "Status: \(status.displayName)"
        }
    }

    private func shouldNotify(for status: DeploymentStatus) -> Bool {
        switch status {
        case .success:
            return notifyOnSuccess
        case .building:
            return notifyOnBuilding
        case .deploying, .initializing, .waiting:
            return notifyOnDeploying
        case .failed, .crashed:
            return notifyOnFailure
        default:
            return false
        }
    }

    private func statusTitle(for status: DeploymentStatus, serviceName: String) -> String {
        switch status {
        case .success:
            return "✅ \(serviceName) Deployed"
        case .building:
            return "🔨 \(serviceName) Building"
        case .deploying, .initializing, .waiting:
            return "🚀 \(serviceName) Deploying"
        case .failed:
            return "❌ \(serviceName) Failed"
        case .crashed:
            return "💥 \(serviceName) Crashed"
        case .error:
            return "⚠️ \(serviceName) Error"
        default:
            return "\(serviceName) Status Changed"
        }
    }

    private func statusBody(for status: DeploymentStatus, serviceName: String) -> String {
        switch status {
        case .success:
            return "Deployment completed successfully"
        case .building:
            return "Build started"
        case .deploying:
            return "Deployment in progress"
        case .failed:
            return "Deployment failed - check Railway dashboard"
        case .crashed:
            return "Service crashed - check Railway dashboard"
        case .error:
            return "Service has errors - check Railway dashboard"
        default:
            return "Status: \(status.displayName)"
        }
    }
}

// MARK: - Notification Delegate for handling clicks

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
