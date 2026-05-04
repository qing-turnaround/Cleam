import Foundation

struct ScanProgress {
    var totalItems: Int
    var scannedItems: Int
    var totalBytes: UInt64
    var currentPath: String
    var isComplete: Bool

    var fraction: Double {
        guard totalItems > 0 else { return 0 }
        return Double(scannedItems) / Double(totalItems)
    }

    static var zero: ScanProgress {
        ScanProgress(totalItems: 0, scannedItems: 0, totalBytes: 0, currentPath: "", isComplete: false)
    }
}
