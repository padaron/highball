import SwiftUI

struct OnboardingView: View {
    @ObservedObject var monitor: StatusMonitor
    @Environment(\.openURL) private var openURL

    @State private var currentStep = 0
    @State private var tokenInput = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var discoveredProjects: [(project: Project, services: [Service])] = []
    @State private var selectedProjectId: String?
    @State private var selectedServiceIds: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Highball")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Railway deployment monitoring")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)

            // Step content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                tokenStep.tag(1)
                servicesStep.tag(2)
                completeStep.tag(3)
            }
            .tabViewStyle(.automatic)

            Spacer()
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - Step Views

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "circle.fill",
                    color: .green,
                    title: "Glanceable Status",
                    description: "Color-coded menu bar icon shows deployment health at a glance"
                )

                FeatureRow(
                    icon: "bell.fill",
                    color: .orange,
                    title: "Instant Notifications",
                    description: "Get alerted when builds start, succeed, or fail"
                )

                FeatureRow(
                    icon: "arrow.up.right.square",
                    color: .blue,
                    title: "Quick Navigation",
                    description: "Jump to Railway dashboard with one click"
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            Button("Get Started") {
                withAnimation {
                    currentStep = 1
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private var tokenStep: some View {
        VStack(spacing: 20) {
            Text("Connect to Railway")
                .font(.headline)

            Text("Enter your Railway API token to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                SecureField("Railway API Token", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                Button("Get a token from Railway →") {
                    openURL(URL(string: "https://railway.com/account/tokens")!)
                }
                .buttonStyle(.link)
                .font(.caption)
            }

            if let error = validationError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Spacer()

            HStack {
                Button("Back") {
                    withAnimation {
                        currentStep = 0
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                if isValidating {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button("Connect") {
                    Task {
                        await validateAndFetchProjects()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(tokenInput.isEmpty || isValidating)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var servicesStep: some View {
        VStack(spacing: 20) {
            Text("Select Services to Monitor")
                .font(.headline)

            if discoveredProjects.isEmpty {
                Text("No projects found")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Project", selection: $selectedProjectId) {
                        Text("Select a project").tag(nil as String?)
                        ForEach(discoveredProjects, id: \.project.id) { item in
                            Text(item.project.name).tag(item.project.id as String?)
                        }
                    }
                    .frame(width: 300)

                    if let projectId = selectedProjectId,
                       let project = discoveredProjects.first(where: { $0.project.id == projectId }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Services")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ForEach(project.services) { service in
                                Toggle(service.name, isOn: Binding(
                                    get: { selectedServiceIds.contains(service.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedServiceIds.insert(service.id)
                                        } else {
                                            selectedServiceIds.remove(service.id)
                                        }
                                    }
                                ))
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
                .frame(width: 300)
            }

            Spacer()

            HStack {
                Button("Back") {
                    withAnimation {
                        currentStep = 1
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    Task {
                        await saveConfiguration()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProjectId == nil || selectedServiceIds.isEmpty)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.headline)

            Text("Highball is now monitoring your Railway services.\nLook for the status icon in your menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Done") {
                // Close the onboarding window - the menu bar is already active
                NSApplication.shared.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Actions

    private func validateAndFetchProjects() async {
        isValidating = true
        validationError = nil

        do {
            // Save token to Keychain
            try KeychainManager.saveToken(tokenInput)

            discoveredProjects = try await monitor.discoverServices(token: tokenInput)

            if discoveredProjects.isEmpty {
                validationError = "No projects found. Check your token permissions."
            } else {
                withAnimation {
                    currentStep = 2
                }
            }
        } catch {
            validationError = error.localizedDescription
        }

        isValidating = false
    }

    private func saveConfiguration() async {
        guard let projectId = selectedProjectId else { return }

        let serviceIds = Array(selectedServiceIds)

        if let project = discoveredProjects.first(where: { $0.project.id == projectId }) {
            let serviceNames = Dictionary(uniqueKeysWithValues:
                project.services
                    .filter { selectedServiceIds.contains($0.id) }
                    .map { ($0.id, $0.name) }
            )

            await monitor.configure(
                token: tokenInput,
                projectId: projectId,
                projectName: project.project.name,
                serviceIds: serviceIds
            )

            monitor.setServiceNames(serviceNames)

            // Request notification permission
            await NotificationManager.shared.requestAuthorization()

            withAnimation {
                currentStep = 3
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
