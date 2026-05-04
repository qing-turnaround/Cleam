import SwiftUI

@MainActor
class DiskAnalyzerViewModel: ObservableObject {
    @Published var entries: [DiskEntry] = []
    @Published var largeFiles: [LargeFile] = []
    @Published var currentPath: URL
    @Published var pathHistory: [URL] = []
    @Published var isScanning = false
    @Published var scanProgress: ScanProgress = .zero
    @Published var selectedEntries: Set<UUID> = Set()
    @Published var showLargeFiles = false
    @Published var freeSpace: UInt64 = 0
    @Published var totalSpace: UInt64 = 0

    private let fileOps: FileOperationService

    init(fileOps: FileOperationService) {
        self.fileOps = fileOps
        self.currentPath = URL.home
    }

    var breadcrumbs: [URL] {
        var crumbs: [URL] = []
        var url = currentPath
        while url.path != "/" {
            crumbs.insert(url, at: 0)
            url = url.deletingLastPathComponent()
        }
        crumbs.insert(URL(fileURLWithPath: "/"), at: 0)
        return crumbs
    }

    func scan() async {
        isScanning = true
        scanProgress = .zero
        entries = []
        largeFiles = []
        selectedEntries.removeAll()

        let fm = FileManager.default
        freeSpace = fm.diskFreeSpace()
        totalSpace = fm.diskTotalSpace()

        let contents = fm.safeContentsOfDirectory(at: currentPath)
        var scannedEntries: [DiskEntry] = []
        var fileHeap = MinHeap<LargeFile>(maxSize: 20)
        var scanned = 0

        for url in contents {
            let isDir = url.isDirectory
            let name = url.lastPathComponent
            let size: UInt64
            let lastAccess = fm.modificationDate(at: url)

            if isDir {
                size = fm.directorySize(at: url)
            } else {
                size = fm.fileSize(at: url)
                fileHeap.insert(LargeFile(path: url, name: name, sizeBytes: size, lastAccessDate: lastAccess))
            }

            scanned += 1
            scanProgress = ScanProgress(
                totalItems: contents.count,
                scannedItems: scanned,
                totalBytes: 0,
                currentPath: name,
                isComplete: false
            )

            scannedEntries.append(DiskEntry(
                name: name,
                path: url,
                sizeBytes: size,
                isDirectory: isDir,
                lastAccessDate: lastAccess
            ))
        }

        let totalSize = scannedEntries.reduce(0) { $0 + $1.sizeBytes }
        for i in scannedEntries.indices {
            scannedEntries[i].percentage = totalSize > 0
                ? Double(scannedEntries[i].sizeBytes) / Double(totalSize) * 100
                : 0
        }

        entries = scannedEntries.sorted { $0.sizeBytes > $1.sizeBytes }
        largeFiles = fileHeap.sorted
        scanProgress.isComplete = true
        isScanning = false
    }

    func navigateInto(_ entry: DiskEntry) {
        guard entry.isDirectory else { return }
        pathHistory.append(currentPath)
        currentPath = entry.path
        Task { await scan() }
    }

    func navigateBack() {
        guard let previous = pathHistory.popLast() else { return }
        currentPath = previous
        Task { await scan() }
    }

    func navigateTo(_ url: URL) {
        pathHistory.removeAll()
        currentPath = url
        Task { await scan() }
    }

    func deleteSelected() async {
        let urls = entries.filter { selectedEntries.contains($0.id) }.map(\.path)
        guard !urls.isEmpty else { return }

        _ = await fileOps.deleteBatch(urls: urls, isDryRun: false) { _, _ in }
        selectedEntries.removeAll()
        await scan()
    }
}
