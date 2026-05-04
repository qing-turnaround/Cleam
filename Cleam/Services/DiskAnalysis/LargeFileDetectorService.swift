import Foundation

actor LargeFileDetectorService {
    private let maxFiles: Int

    init(maxFiles: Int = 20) {
        self.maxFiles = maxFiles
    }

    func detect(in directory: URL, minSize: UInt64 = 50_000_000) async -> [LargeFile] {
        var heap = MinHeap<LargeFile>(maxSize: maxFiles)

        await scanRecursive(directory: directory, heap: &heap, minSize: minSize, depth: 0, maxDepth: 10)

        return heap.sorted
    }

    private func scanRecursive(directory: URL, heap: inout MinHeap<LargeFile>, minSize: UInt64, depth: Int, maxDepth: Int) async {
        guard depth < maxDepth else { return }

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .contentAccessDateKey],
            options: [.skipsPackageDescendants]
        ) else { return }

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .contentAccessDateKey]),
                  values.isRegularFile == true,
                  let size = values.totalFileAllocatedSize,
                  UInt64(size) >= minSize else { continue }

            let file = LargeFile(
                path: url,
                name: url.lastPathComponent,
                sizeBytes: UInt64(size),
                lastAccessDate: values.contentAccessDate
            )
            heap.insert(file)
        }
    }
}
