import Foundation

enum DurationFormatter {
    static func relativeDate(_ date: Date?) -> String {
        guard let date = date else { return NSLocalizedString("Unknown", bundle: .module, comment: "") }
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)

        switch days {
        case 0: return NSLocalizedString("Today", bundle: .module, comment: "")
        case 1: return NSLocalizedString("Yesterday", bundle: .module, comment: "")
        case 2..<7: return String(format: NSLocalizedString("%lld days ago", bundle: .module, comment: ""), days)
        case 7..<30: return String(format: NSLocalizedString("%lld weeks ago", bundle: .module, comment: ""), days / 7)
        case 30..<365: return String(format: NSLocalizedString("%lld months ago", bundle: .module, comment: ""), days / 30)
        default: return String(format: NSLocalizedString("%lld years ago", bundle: .module, comment: ""), days / 365)
        }
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 1 { return "< 1s" }
        if interval < 60 { return "\(Int(interval))s" }
        if interval < 3600 { return "\(Int(interval / 60))m \(Int(interval) % 60)s" }
        return "\(Int(interval / 3600))h \(Int(interval / 60) % 60)m"
    }
}
