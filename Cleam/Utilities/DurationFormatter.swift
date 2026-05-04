import Foundation

enum DurationFormatter {
    static func relativeDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)

        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2..<7: return "\(days) days ago"
        case 7..<30: return "\(days / 7) weeks ago"
        case 30..<365: return "\(days / 30) months ago"
        default: return "\(days / 365) years ago"
        }
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 1 { return "< 1s" }
        if interval < 60 { return "\(Int(interval))s" }
        if interval < 3600 { return "\(Int(interval / 60))m \(Int(interval) % 60)s" }
        return "\(Int(interval / 3600))h \(Int(interval / 60) % 60)m"
    }
}
