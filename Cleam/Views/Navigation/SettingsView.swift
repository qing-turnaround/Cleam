import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var deleteMode: FileOperationMode = .trash
    @State private var permissionStatus: PermissionStatus = .unknown

    private let permissionService = PermissionService()

    var body: some View {
        Form {
            Section("General") {
                Picker("Delete Mode", selection: $deleteMode) {
                    Text("Move to Trash").tag(FileOperationMode.trash)
                    Text("Permanent Delete").tag(FileOperationMode.permanent)
                }

                Toggle("Dry Run by Default", isOn: $appState.isDryRun)
            }

            Section("Permissions") {
                HStack {
                    Text("Full Disk Access")
                    Spacer()
                    statusBadge
                    Button("Open Settings") {
                        Task { await permissionService.openFullDiskAccessSettings() }
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppState.version)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Based on")
                    Spacer()
                    Text("Mole by tw93")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data") {
                HStack {
                    Text("Config Directory")
                    Spacer()
                    Text(appState.configDirectory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cache Directory")
                    Spacer()
                    Text(appState.cacheDirectory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Log Directory")
                    Spacer()
                    Text(appState.logDirectory.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onAppear {
            Task {
                permissionStatus = await permissionService.checkFullDiskAccess()
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch permissionStatus {
        case .granted:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .denied:
            Label("Not Granted", systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .unknown:
            Label("Unknown", systemImage: "questionmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}
