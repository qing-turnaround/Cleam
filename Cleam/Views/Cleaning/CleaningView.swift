import SwiftUI

struct CleaningView: View {
    @StateObject private var viewModel: CleaningViewModel

    init() {
        _viewModel = StateObject(wrappedValue: CleaningViewModel(fileOps: ServiceFactory.fileOps))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isDryRun {
                DryRunBanner()
            }

            if viewModel.isScanning {
                scanningView
            } else if viewModel.session.totalItemCount == 0 && viewModel.result == nil {
                EmptyStateView(
                    icon: "sparkles",
                    title: "System Cleaning",
                    message: "Scan your system to find caches, logs, and temporary files that can be safely removed.",
                    action: { Task { await viewModel.scan() } },
                    actionLabel: "Start Scan"
                )
            } else if let result = viewModel.result {
                resultView(result)
            } else {
                categoryList
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle("Dry Run", isOn: $viewModel.isDryRun)
                    .toggleStyle(.switch)

                if viewModel.session.totalItemCount > 0 {
                    Button("Clean") {
                        Task { await viewModel.clean() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.session.selectedItemCount == 0 || viewModel.isCleaning)
                }

                Button("Scan") {
                    Task { await viewModel.scan() }
                }
                .disabled(viewModel.isScanning)
            }
        }
        .navigationTitle("Clean")
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning...")
                .font(.headline)
            if !viewModel.scanProgress.currentPath.isEmpty {
                Text(viewModel.scanProgress.currentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var categoryList: some View {
        List {
            ForEach(CleanCategory.allCases) { category in
                if let items = viewModel.session.items[category], !items.isEmpty {
                    CleanCategorySection(
                        category: category,
                        items: items,
                        onToggleAll: { selected in
                            viewModel.toggleCategory(category, selected: selected)
                        }
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("\(viewModel.session.selectedItemCount) items selected")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(ByteFormatter.format(viewModel.session.selectedSizeBytes))
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding()
            .background(.bar)
        }
    }

    private func resultView(_ result: OperationResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(result.success ? Color.green : Color.yellow)

            Text(result.success ? "Cleaning Complete" : "Cleaning Completed with Errors")
                .font(.title2)

            Text(result.summary)
                .foregroundStyle(.secondary)

            if !result.errors.isEmpty {
                GroupBox("Errors") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.errors) { error in
                                Text("\(error.path.lastPathComponent): \(error.message)")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                .frame(maxWidth: 400)
            }

            Button("Scan Again") {
                viewModel.result = nil
                Task { await viewModel.scan() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CleanCategorySection: View {
    let category: CleanCategory
    let items: [CleanableItem]
    let onToggleAll: (Bool) -> Void

    @State private var isExpanded = true

    private var allSelected: Bool {
        items.allSatisfy(\.isSelected)
    }

    private var totalSize: UInt64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(items) { item in
                HStack {
                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isSelected ? Color.blue : Color.secondary)

                    Text(item.displayName)
                        .lineLimit(1)

                    Spacer()

                    if item.riskLevel >= .medium {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }

                    SizeLabel(bytes: item.sizeBytes)
                }
                .contentShape(Rectangle())
            }
        } label: {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                Text(category.localizedName)
                    .font(.headline)

                Spacer()

                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SizeLabel(bytes: totalSize)
                    .font(.subheadline)
            }
        }
    }
}

struct DryRunBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "eye.fill")
            Text("Dry Run Mode — No files will be deleted")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.orange)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
    }
}
