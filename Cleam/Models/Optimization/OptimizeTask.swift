import Foundation

enum OptimizeCategory: String, CaseIterable {
    case dns = "DNS & Network"
    case spotlight = "Spotlight"
    case quicklook = "QuickLook"
    case launchServices = "Launch Services"
    case sqlite = "Database Maintenance"
    case fontCache = "Font Cache"
    case launchAgents = "Launch Agents"
    case maintenance = "System Maintenance"
}

enum TaskPrerequisite {
    case appNotRunning(String)
    case acPower
    case sudoRequired

    var description: String {
        switch self {
        case .appNotRunning(let app): return "Close \(app) first"
        case .acPower: return "Connect to power"
        case .sudoRequired: return "Requires admin privileges"
        }
    }
}

enum OptimizeTaskStatus: Equatable {
    case idle
    case checking
    case running
    case completed(success: Bool, message: String)
    case skipped(reason: String)
}

struct OptimizeTask: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: OptimizeCategory
    let riskLevel: CleanRiskLevel
    let requiresSudo: Bool
    let prerequisites: [TaskPrerequisite]
    var status: OptimizeTaskStatus

    init(
        id: String,
        name: String,
        description: String,
        category: OptimizeCategory,
        riskLevel: CleanRiskLevel = .low,
        requiresSudo: Bool = false,
        prerequisites: [TaskPrerequisite] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.riskLevel = riskLevel
        self.requiresSudo = requiresSudo
        self.prerequisites = prerequisites
        self.status = .idle
    }
}
