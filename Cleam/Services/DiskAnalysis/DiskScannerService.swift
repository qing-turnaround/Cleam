import Foundation

actor DiskScannerService {
    private let fileManager = FileManager.default
    private let maxConcurrentScans = 8

    struct ScanResult {
        let entries: [DiskEntry]
        let totalSize: UInt64
        let fileCount: Int
        let directoryCount: Int
    }

    func scan(directory: URL, progress: @escaping @Sendable (String, Int) -> Void) async throws -> ScanResult {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .totalFileAllocatedSizeKey,
                .contentAccessDateKey,
                .isSymbolicLinkKey,
            ],
            options: []
        )

        var entries: [DiskEntry] = []
        var totalSize: UInt64 = 0
        var fileCount = 0
        var directoryCount = 0
        var scanned = 0

        await withTaskGroup(of: DiskEntry?.self) { group in
            var pending = 0
            var index = 0

            while index < contents.count || pending > 0 {
                while index < contents.count && pending < maxConcurrentScans {
                    let url = contents[index]
                    index += 1
                    pending += 1

                    group.addTask { [fileManager] in
                        let name = url.lastPathComponent
                        let values = try? url.resourceValues(forKeys: [
                            .isDirectoryKey,
                            .totalFileAllocatedSizeKey,
                            .contentAccessDateKey,
                            .isSymbolicLinkKey,
                        ])

                        // Skip symbolic links to avoid loops
                        if values?.isSymbolicLink == true { return nil }

                        let isDir = values?.isDirectory ?? false
                        let lastAccess = values?.contentAccessDate
                        let size: UInt64

                        if isDir {
                            size = fileManager.directorySize(at: url)
                        } else {
                            size = UInt64(values?.totalFileAllocatedSize ?? 0)
                        }

                        return DiskEntry(
                            name: name,
                            path: url,
                            sizeBytes: size,
                            isDirectory: isDir,
                            lastAccessDate: lastAccess
                        )
                    }
                }

                if let entry = await group.next() {
                    pending -= 1
                    if let entry = entry {
                        scanned += 1
                        progress(entry.name, scanned)

                        if entry.isDirectory { directoryCount += 1 }
                        else { fileCount += 1 }
                        totalSize += entry.sizeBytes
                        entries.append(entry)
                    }
                }
            }
        }

        // Calculate percentages
        for i in entries.indices {
            entries[i].percentage = totalSize > 0
                ? Double(entries[i].sizeBytes) / Double(totalSize) * 100
                : 0
        }

        entries.sort { $0.sizeBytes > $1.sizeBytes }

        return ScanResult(
            entries: entries,
            totalSize: totalSize,
            fileCount: fileCount,
            directoryCount: directoryCount
        )
    }
}
