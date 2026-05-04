import SwiftUI

struct DiskAnalyzerView: View {
    @StateObject private var viewModel: DiskAnalyzerViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DiskAnalyzerViewModel(fileOps: ServiceFactory.fileOps))
    }

    var body: some View {
        HSplitView {
            mainContent
                .frame(minWidth: 500)

            if viewModel.showLargeFiles {
                LargeFilesPanel(files: viewModel.largeFiles)
                    .frame(minWidth: 250, maxWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle(isOn: $viewModel.showLargeFiles) {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .help("Show Large Files")

                if !viewModel.selectedEntries.isEmpty {
                    Button {
                        Task { await viewModel.deleteSelected() }
                    } label: {
                        Label("Delete \(viewModel.selectedEntries.count) items", systemImage: "trash")
                    }
                    .tint(.red)
                }

                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isScanning)
            }
        }
        .navigationTitle("Disk Analyzer")
        .onAppear {
            Task { await viewModel.scan() }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            breadcrumbBar

            Divider()

            if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning \(viewModel.currentPath.lastPathComponent)...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                entryList
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentPath.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(ByteFormatter.format(viewModel.freeSpace)) free")
                    .font(.caption)
                    .fontWeight(.medium)
                ProgressBarView(
                    value: Double(viewModel.totalSpace - viewModel.freeSpace),
                    maxValue: Double(viewModel.totalSpace),
                    height: 6
                )
                .frame(width: 120)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(viewModel.breadcrumbs, id: \.path) { url in
                    Button {
                        viewModel.navigateTo(url)
                    } label: {
                        Text(url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(url == viewModel.currentPath ? .primary : .blue)
                    }
                    .buttonStyle(.plain)

                    if url != viewModel.breadcrumbs.last {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private var entryList: some View {
        List(viewModel.entries, selection: $viewModel.selectedEntries) { entry in
            DiskEntryRow(entry: entry)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    viewModel.navigateInto(entry)
                }
        }
        .listStyle(.inset)
        .safeAreaInset(edge: .top) {
            if !viewModel.pathHistory.isEmpty {
                Button {
                    viewModel.navigateBack()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

struct DiskEntryRow: View {
    let entry: DiskEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                .frame(width: 20)

            Text(entry.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: "%.1f%%", entry.percentage))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)

            ProgressBarView(
                value: entry.percentage,
                maxValue: 100,
                height: 6
            )
            .frame(width: 100)

            SizeLabel(bytes: entry.sizeBytes)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

struct LargeFilesPanel: View {
    let files: [LargeFile]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Large Files", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            if files.isEmpty {
                Text("No large files found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List(files) { file in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.caption)
                            .lineLimit(1)
                        HStack {
                            SizeLabel(bytes: file.sizeBytes)
                                .font(.caption2)
                            Spacer()
                            if let date = file.lastAccessDate {
                                Text(DurationFormatter.relativeDate(date))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
    }
}
