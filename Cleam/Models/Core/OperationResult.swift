import Foundation

struct OperationResult {
    let success: Bool
    let freedBytes: UInt64
    let deletedCount: Int
    let failedCount: Int
    let errors: [OperationError]
    let duration: TimeInterval

    var summary: String {
        if success {
            return "Freed \(ByteFormatter.format(freedBytes)) by removing \(deletedCount) items"
        } else {
            return "Completed with \(failedCount) errors out of \(deletedCount + failedCount) items"
        }
    }
}

struct OperationError: Identifiable {
    let id = UUID()
    let path: URL
    let message: String
}
