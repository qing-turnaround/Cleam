import Foundation

enum CleanRiskLevel: Int, Comparable, Codable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: CleanRiskLevel, rhs: CleanRiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .low: return NSLocalizedString("Low", bundle: .module, comment: "")
        case .medium: return NSLocalizedString("Medium", bundle: .module, comment: "")
        case .high: return NSLocalizedString("High", bundle: .module, comment: "")
        }
    }
}

struct CleanableItem: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let displayName: String
    let sizeBytes: UInt64
    let modificationDate: Date?
    let category: CleanCategory
    let riskLevel: CleanRiskLevel
    var isSelected: Bool

    init(
        path: URL,
        displayName: String,
        sizeBytes: UInt64,
        modificationDate: Date? = nil,
        category: CleanCategory,
        riskLevel: CleanRiskLevel = .low,
        isSelected: Bool = true
    ) {
        self.id = UUID()
        self.path = path
        self.displayName = displayName
        self.sizeBytes = sizeBytes
        self.modificationDate = modificationDate
        self.category = category
        self.riskLevel = riskLevel
        self.isSelected = isSelected
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CleanableItem, rhs: CleanableItem) -> Bool {
        lhs.id == rhs.id
    }
}
