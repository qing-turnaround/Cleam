import SwiftUI

struct OptimizationView: View {
    @StateObject private var viewModel: OptimizationViewModel

    init() {
        _viewModel = StateObject(wrappedValue: OptimizationViewModel())
    }

    var body: some View {
        List {
            ForEach(OptimizeCategory.allCases, id: \.self) { category in
                let tasks = viewModel.tasks.filter { $0.category == category }
                if !tasks.isEmpty {
                    Section(category.localizedName) {
                        ForEach(tasks) { task in
                            OptimizeTaskRow(task: task) {
                                Task { await viewModel.runTask(task.id) }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Reset") {
                    viewModel.resetAll()
                }

                Button("Run All") {
                    Task { await viewModel.runAll() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)
            }
        }
        .navigationTitle("Optimize")
    }
}

struct OptimizeTaskRow: View {
    let task: OptimizeTask
    let onRun: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .fontWeight(.medium)

                    if task.riskLevel >= .medium {
                        Text(task.riskLevel.label)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(task.riskLevel == .high ? Color.red.opacity(0.15) : Color.yellow.opacity(0.15))
                            .foregroundStyle(task.riskLevel == .high ? Color.red : Color.orange)
                            .clipShape(Capsule())
                    }

                    if task.requiresSudo {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Text(task.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !task.prerequisites.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text(task.prerequisites.map(\.description).joined(separator: ", "))
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }

            Spacer()

            statusDetail

            runButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .idle:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .checking, .running:
            ProgressView()
                .scaleEffect(0.7)
        case .completed(let success, _):
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(success ? Color.green : Color.red)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var statusDetail: some View {
        switch task.status {
        case .completed(_, let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .skipped(let reason):
            Text(reason)
                .font(.caption)
                .foregroundStyle(.orange)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var runButton: some View {
        switch task.status {
        case .running, .checking:
            EmptyView()
        default:
            Button("Run") { onRun() }
                .buttonStyle(.bordered)
        }
    }
}
