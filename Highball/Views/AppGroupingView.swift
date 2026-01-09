import SwiftUI

struct AppGroupingView: View {
    @ObservedObject var monitor: StatusMonitor

    @State private var showingCreateApp = false
    @State private var editingApp: MonitoredApp?

    var body: some View {
        Form {
            Section {
                ForEach(monitor.apps) { app in
                    AppGroupRow(app: app, monitor: monitor)
                        .contextMenu {
                            Button("Edit") {
                                editingApp = app
                            }
                            Button("Delete", role: .destructive) {
                                monitor.deleteApp(app.id)
                            }
                        }
                }

                if monitor.apps.isEmpty {
                    Text("No apps configured")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } header: {
                Text("Apps")
            }

            Section {
                ForEach(monitor.getUngroupedServices()) { service in
                    HStack {
                        Circle()
                            .fill(service.status.color)
                            .frame(width: 8, height: 8)
                        Text(service.serviceName)
                        Spacer()
                        Text("Ungrouped")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }

                if monitor.getUngroupedServices().isEmpty && !monitor.services.isEmpty {
                    Text("All services are grouped")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } header: {
                Text("Ungrouped Services")
            }

            Section {
                Button {
                    showingCreateApp = true
                } label: {
                    Label("Create App", systemImage: "plus.circle.fill")
                }
                .disabled(monitor.services.isEmpty)
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingCreateApp) {
            CreateAppSheet(monitor: monitor, isPresented: $showingCreateApp)
        }
        .sheet(item: $editingApp) { app in
            EditAppSheet(app: app, monitor: monitor, isPresented: .init(
                get: { editingApp != nil },
                set: { if !$0 { editingApp = nil } }
            ))
        }
    }
}

struct AppGroupRow: View {
    let app: MonitoredApp
    @ObservedObject var monitor: StatusMonitor

    var appStatus: DeploymentStatus {
        app.aggregateStatus(services: monitor.services)
    }

    var body: some View {
        HStack {
            Circle()
                .fill(appStatus.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                Text("\(app.serviceIds.count) services")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(appStatus.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CreateAppSheet: View {
    @ObservedObject var monitor: StatusMonitor
    @Binding var isPresented: Bool

    @State private var appName = ""
    @State private var selectedServiceIds: Set<String> = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Create App")
                .font(.headline)

            TextField("App Name", text: $appName)
                .textFieldStyle(.roundedBorder)

            Text("Select Services")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(monitor.services, selection: $selectedServiceIds) { service in
                HStack {
                    Circle()
                        .fill(service.status.color)
                        .frame(width: 8, height: 8)
                    Text(service.serviceName)
                }
                .tag(service.id)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    monitor.createApp(name: appName, serviceIds: Array(selectedServiceIds))
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(appName.isEmpty || selectedServiceIds.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

struct EditAppSheet: View {
    let app: MonitoredApp
    @ObservedObject var monitor: StatusMonitor
    @Binding var isPresented: Bool

    @State private var appName: String
    @State private var selectedServiceIds: Set<String>

    init(app: MonitoredApp, monitor: StatusMonitor, isPresented: Binding<Bool>) {
        self.app = app
        self.monitor = monitor
        self._isPresented = isPresented
        self._appName = State(initialValue: app.name)
        self._selectedServiceIds = State(initialValue: Set(app.serviceIds))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit App")
                .font(.headline)

            TextField("App Name", text: $appName)
                .textFieldStyle(.roundedBorder)

            Text("Select Services")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(monitor.services, selection: $selectedServiceIds) { service in
                HStack {
                    Circle()
                        .fill(service.status.color)
                        .frame(width: 8, height: 8)
                    Text(service.serviceName)
                }
                .tag(service.id)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    monitor.updateApp(app.id, name: appName, serviceIds: Array(selectedServiceIds))
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(appName.isEmpty || selectedServiceIds.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
