import SwiftUI

extension Color {
    static let danger = Color.red
    static let warning = Color.yellow
    static let ok = Color.green
    static let info = Color.blue
    static let subtle = Color.secondary.opacity(0.5)

    static func sizeColor(percentage: Double) -> Color {
        if percentage >= 50 { return .danger }
        if percentage >= 20 { return .warning }
        if percentage >= 5 { return .info }
        return .secondary.opacity(0.3)
    }

    static func healthColor(score: Int) -> Color {
        switch score {
        case 90...100: return .ok
        case 75..<90: return .info
        case 50..<75: return .warning
        default: return .danger
        }
    }
}
