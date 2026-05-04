import Foundation

actor DiskCacheService {
    private let cacheDirectory: URL
    private let overviewTTL: TimeInterval = 7 * 24 * 3600  // 7 days
    private let detailTTL: TimeInterval = 3 * 24 * 3600    // 3 days

    struct CachedScan: Codable {
        let path: String
        let timestamp: Date
        let entries: [CachedEntry]
        let totalSize: UInt64
    }

    struct CachedEntry: Codable {
        let name: String
        let path: String
        let sizeBytes: UInt64
        let isDirectory: Bool
        let percentage: Double
    }

    init() {
        self.cacheDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache")
            .appendingPathComponent("Cleam")
            .appendingPathComponent("scans")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func getCached(for path: URL) -> CachedScan? {
        let cacheFile = cacheFileURL(for: path)
        guard let data = try? Data(contentsOf: cacheFile),
              let cached = try? JSONDecoder().decode(CachedScan.self, from: data) else {
            return nil
        }

        let ttl = path.pathComponents.count <= 3 ? overviewTTL : detailTTL
        guard Date().timeIntervalSince(cached.timestamp) < ttl else {
            try? FileManager.default.removeItem(at: cacheFile)
            return nil
        }

        return cached
    }

    func cache(path: URL, entries: [DiskEntry], totalSize: UInt64) {
        let cachedEntries = entries.map { entry in
            CachedEntry(
                name: entry.name,
                path: entry.path.path,
                sizeBytes: entry.sizeBytes,
                isDirectory: entry.isDirectory,
                percentage: entry.percentage
            )
        }

        let scan = CachedScan(
            path: path.path,
            timestamp: Date(),
            entries: cachedEntries,
            totalSize: totalSize
        )

        if let data = try? JSONEncoder().encode(scan) {
            let cacheFile = cacheFileURL(for: path)
            try? data.write(to: cacheFile)
        }
    }

    func invalidate(for path: URL) {
        let cacheFile = cacheFileURL(for: path)
        try? FileManager.default.removeItem(at: cacheFile)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func cacheFileURL(for path: URL) -> URL {
        let hash = path.path.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .prefix(64)
        return cacheDirectory.appendingPathComponent(String(hash) + ".json")
    }
}
