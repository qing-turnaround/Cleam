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
            return String(format: NSLocalizedString("Freed %@ by removing %lld items", bundle: .module, comment: ""), ByteFormatter.format(freedBytes), deletedCount)
        } else {
            return String(format: NSLocalizedString("Completed with %lld errors out of %lld items", bundle: .module, comment: ""), failedCount, deletedCount + failedCount)
        }
    }
}

struct OperationError: Identifiable {
    let id = UUID()
    let path: URL
    let message: String
}
