import Foundation

struct DiskEntry: Identifiable {
    let id: UUID
    let name: String
    let path: URL
    let sizeBytes: UInt64
    let isDirectory: Bool
    let lastAccessDate: Date?
    var percentage: Double
    var children: [DiskEntry]?

    init(
        name: String,
        path: URL,
        sizeBytes: UInt64,
        isDirectory: Bool,
        lastAccessDate: Date? = nil,
        percentage: Double = 0,
        children: [DiskEntry]? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
        self.lastAccessDate = lastAccessDate
        self.percentage = percentage
        self.children = children
    }
}

struct LargeFile: Identifiable, Comparable {
    let id: UUID
    let path: URL
    let name: String
    let sizeBytes: UInt64
    let lastAccessDate: Date?

    init(path: URL, name: String, sizeBytes: UInt64, lastAccessDate: Date? = nil) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.sizeBytes = sizeBytes
        self.lastAccessDate = lastAccessDate
    }

    static func < (lhs: LargeFile, rhs: LargeFile) -> Bool {
        lhs.sizeBytes < rhs.sizeBytes
    }
}

enum InsightCategory: String {
    case iosBackups = "iOS Backups"
    case oldDownloads = "Old Downloads"
    case devCaches = "Developer Caches"
    case appCaches = "App Caches"
}

struct DiskInsight: Identifiable {
    let id: UUID
    let name: String
    let path: URL
    let sizeBytes: UInt64
    let icon: String
    let category: InsightCategory

    init(name: String, path: URL, sizeBytes: UInt64, icon: String, category: InsightCategory) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.icon = icon
        self.category = category
    }
}
