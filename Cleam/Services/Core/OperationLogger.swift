import Foundation

actor OperationLogger {
    private let logURL: URL
    private let maxLogSize: UInt64 = 5_000_000
    private let dateFormatter: DateFormatter

    init() {
        let logDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Cleam")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        self.logURL = logDir.appendingPathComponent("operations.log")

        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    func log(operation: String, path: String, sizeBytes: UInt64, status: String) {
        rotateIfNeeded()

        let timestamp = dateFormatter.string(from: Date())
        let line = "\(timestamp)\t\(operation)\t\(path)\t\(sizeBytes)\t\(status)\n"

        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }

    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: logURL.path),
              let size = attrs[.size] as? UInt64,
              size > maxLogSize else {
            return
        }
        let backupURL = logURL.deletingLastPathComponent().appendingPathComponent("operations.log.1")
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.moveItem(at: logURL, to: backupURL)
    }
}
