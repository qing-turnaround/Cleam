import Foundation

struct CleanSession {
    var items: [CleanCategory: [CleanableItem]]
    var isDryRun: Bool
    var startTime: Date
    var freedBytes: UInt64
    var deletedCount: Int

    var totalSizeBytes: UInt64 {
        items.values.flatMap { $0 }.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedSizeBytes: UInt64 {
        items.values.flatMap { $0 }.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    var totalItemCount: Int {
        items.values.reduce(0) { $0 + $1.count }
    }

    var selectedItemCount: Int {
        items.values.flatMap { $0 }.filter(\.isSelected).count
    }

    static var empty: CleanSession {
        CleanSession(items: [:], isDryRun: false, startTime: Date(), freedBytes: 0, deletedCount: 0)
    }
}
