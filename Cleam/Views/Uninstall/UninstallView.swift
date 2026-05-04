import SwiftUI

struct UninstallView: View {
    @StateObject private var viewModel: UninstallViewModel

    init() {
        _viewModel = StateObject(wrappedValue: UninstallViewModel(
            fileOps: ServiceFactory.fileOps,
            shell: ServiceFactory.shell,
            protectionList: ServiceFactory.protectionList
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                ProgressView("Scanning applications...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.apps.isEmpty {
                EmptyStateView(
                    icon: "trash",
                    title: "App Uninstaller",
                    message: "Scan your Applications folder to find installed apps and their associated files.",
                    action: { Task { await viewModel.scanApps() } },
                    actionLabel: "Scan Apps"
                )
            } else {
                appList
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Sort", selection: $viewModel.sortOrder) {
                    ForEach(UninstallViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.localizedName).tag(order)
                    }
                }

                Button("Scan") {
                    Task { await viewModel.scanApps() }
                }
                .disabled(viewModel.isScanning)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search apps...")
        .navigationTitle("Uninstall")
        .sheet(isPresented: $viewModel.showConfirmation) {
            if let plan = viewModel.uninstallPlan {
                UninstallConfirmationSheet(
                    plan: plan,
                    isUninstalling: viewModel.isUninstalling,
                    onConfirm: { Task { await viewModel.executeUninstall() } },
                    onCancel: { viewModel.showConfirmation = false }
                )
            }
        }
    }

    private var appList: some View {
        List(viewModel.filteredApps) { app in
            AppRow(app: app) {
                Task { await viewModel.prepareUninstall(for: app.id) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("\(viewModel.apps.count) applications found")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(.bar)
        }
    }
}

struct AppRow: View {
    let app: InstalledApp
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(app.name)
                        .fontWeight(.medium)

                    if app.isProtected {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let lastUsed = app.lastUsedDate {
                Text(DurationFormatter.relativeDate(lastUsed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .trailing)
            }

            SizeLabel(bytes: app.sizeBytes)
                .frame(width: 80, alignment: .trailing)

            Button("Uninstall") {
                onUninstall()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(app.isProtected)
        }
        .padding(.vertical, 4)
    }
}

struct UninstallConfirmationSheet: View {
    let plan: UninstallPlan
    let isUninstalling: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(nsImage: plan.app.icon)
                    .resizable()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading) {
                    Text("Uninstall \(plan.app.name)")
                        .font(.headline)
                    Text("Total: \(ByteFormatter.format(plan.totalSizeBytes))")
                        .foregroundStyle(.secondary)
                }
            }

            if plan.isRunning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("\(plan.app.name) is currently running and will be terminated.")
                        .font(.caption)
                }
            }

            if plan.app.isDataProtected {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(.orange)
                    Text("This app may contain sensitive data. Proceed with caution.")
                        .font(.caption)
                }
            }

            Divider()

            Text("The following files will be removed:")
                .font(.subheadline)
                .fontWeight(.medium)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(.blue)
                        Text(plan.app.path.path)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        SizeLabel(bytes: plan.app.sizeBytes)
                            .font(.caption)
                    }

                    ForEach(plan.remnants) { remnant in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.secondary)
                            Text(remnant.path.path)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            SizeLabel(bytes: remnant.sizeBytes)
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                if isUninstalling {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button("Uninstall", action: onConfirm)
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            }
        }
        .padding(20)
        .frame(width: 550, height: 450)
    }
}
