import SwiftUI

struct ProjectPurgeView: View {
    @StateObject private var viewModel: ProjectPurgeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProjectPurgeViewModel(fileOps: ServiceFactory.fileOps))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning for projects...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.projects.isEmpty && !viewModel.hasScanned {
                EmptyStateView(
                    icon: "folder.badge.minus",
                    title: "Project Purge",
                    message: "Scan your development directories to find project build artifacts like node_modules, .build, target, etc.",
                    action: { Task { await viewModel.scan() } },
                    actionLabel: "Scan Projects"
                )
            } else if viewModel.projects.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Artifacts Found",
                    message: "No project build artifacts were found in the scanned directories.",
                    action: { Task { await viewModel.scan() } },
                    actionLabel: "Scan Again"
                )
            } else {
                projectList
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.selectedArtifactCount > 0 {
                    Button("Purge \(viewModel.selectedArtifactCount) artifacts") {
                        Task { await viewModel.purgeSelected() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

                Button("Scan") {
                    Task { await viewModel.scan() }
                }
                .disabled(viewModel.isScanning)
            }
        }
        .navigationTitle("Project Purge")
    }

    private var projectList: some View {
        List {
            ForEach(Array(viewModel.projects.enumerated()), id: \.element.id) { projectIndex, project in
                DisclosureGroup {
                    ForEach(Array(project.artifacts.enumerated()), id: \.element.id) { artifactIndex, artifact in
                        HStack(spacing: 10) {
                            Image(systemName: artifact.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(artifact.isSelected ? Color.blue : Color.secondary)
                                .onTapGesture {
                                    viewModel.toggleArtifact(projectIndex: projectIndex, artifactIndex: artifactIndex)
                                }

                            Image(systemName: "folder.fill")
                                .foregroundStyle(.orange)

                            Text(artifact.name)
                                .font(.body)

                            Spacer()

                            if let date = artifact.lastModified {
                                Text(DurationFormatter.relativeDate(date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            SizeLabel(bytes: artifact.sizeBytes)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: project.projectType.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .fontWeight(.medium)
                            Text(project.path.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(project.projectType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())

                        SizeLabel(bytes: project.totalArtifactSize)
                            .font(.subheadline)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("\(viewModel.projects.count) projects found")
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.selectedArtifactCount > 0 {
                    Text("\(viewModel.selectedArtifactCount) artifacts · \(ByteFormatter.format(viewModel.totalPurgeSize))")
                        .font(.headline)
                        .monospacedDigit()
                }
            }
            .padding()
            .background(.bar)
        }
    }
}
