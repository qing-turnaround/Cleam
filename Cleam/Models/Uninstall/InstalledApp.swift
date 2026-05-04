import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let path: URL
    let bundleIdentifier: String
    let icon: NSImage
    let sizeBytes: UInt64
    let lastUsedDate: Date?
    let isFromHomebrew: Bool
    let brewCaskName: String?
    let isProtected: Bool
    let isDataProtected: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
}

enum RemnantKind: String, CaseIterable {
    case preferences = "Preferences"
    case caches = "Caches"
    case applicationSupport = "Application Support"
    case logs = "Logs"
    case containers = "Containers"
    case launchAgents = "Launch Agents"
    case launchDaemons = "Launch Daemons"
    case loginItems = "Login Items"
    case savedState = "Saved State"
    case receipts = "Receipts"
    case crashReports = "Crash Reports"
    case other = "Other"
}

struct AppRemnant: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let kind: RemnantKind
    let sizeBytes: UInt64

    init(path: URL, kind: RemnantKind, sizeBytes: UInt64) {
        self.id = UUID()
        self.path = path
        self.kind = kind
        self.sizeBytes = sizeBytes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppRemnant, rhs: AppRemnant) -> Bool {
        lhs.id == rhs.id
    }
}

struct UninstallPlan {
    let app: InstalledApp
    let remnants: [AppRemnant]
    let requiresSudo: Bool
    let isRunning: Bool

    var totalSizeBytes: UInt64 {
        app.sizeBytes + remnants.reduce(0) { $0 + $1.sizeBytes }
    }
}
