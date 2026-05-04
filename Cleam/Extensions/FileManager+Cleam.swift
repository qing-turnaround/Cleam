import Foundation

extension FileManager {
    func directorySize(at url: URL) -> UInt64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var totalSize: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let size = resourceValues.totalFileAllocatedSize else {
                continue
            }
            totalSize += UInt64(size)
        }
        return totalSize
    }

    func fileSize(at url: URL) -> UInt64 {
        guard let attrs = try? attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else {
            return 0
        }
        return size
    }

    func modificationDate(at url: URL) -> Date? {
        guard let attrs = try? attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date else {
            return nil
        }
        return date
    }

    func diskFreeSpace(at path: String = "/") -> UInt64 {
        guard let attrs = try? attributesOfFileSystem(forPath: path),
              let freeSpace = attrs[.systemFreeSize] as? UInt64 else {
            return 0
        }
        return freeSpace
    }

    func diskTotalSpace(at path: String = "/") -> UInt64 {
        guard let attrs = try? attributesOfFileSystem(forPath: path),
              let totalSpace = attrs[.systemSize] as? UInt64 else {
            return 0
        }
        return totalSpace
    }

    func safeContentsOfDirectory(at url: URL) -> [URL] {
        (try? contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey], options: [.skipsPackageDescendants])) ?? []
    }
}
