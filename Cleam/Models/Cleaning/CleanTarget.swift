import Foundation

struct CleanTarget: Identifiable {
    let id: UUID
    let category: CleanCategory
    let displayName: String
    let pathPatterns: [String]
    let riskLevel: CleanRiskLevel
    let requiresSudo: Bool
    let ageThresholdDays: Int?
    let filePatterns: [String]?

    init(
        category: CleanCategory,
        displayName: String,
        pathPatterns: [String],
        riskLevel: CleanRiskLevel = .low,
        requiresSudo: Bool = false,
        ageThresholdDays: Int? = nil,
        filePatterns: [String]? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.displayName = displayName
        self.pathPatterns = pathPatterns
        self.riskLevel = riskLevel
        self.requiresSudo = requiresSudo
        self.ageThresholdDays = ageThresholdDays
        self.filePatterns = filePatterns
    }
}
