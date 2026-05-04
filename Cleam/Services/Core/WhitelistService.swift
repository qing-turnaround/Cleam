import Foundation

actor WhitelistService {
    private var whitelistedPatterns: [String] = []
    private let configURL: URL

    init() {
        self.configURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("Cleam")
            .appendingPathComponent("whitelist")
        loadWhitelist()
    }

    func isWhitelisted(path: String) -> Bool {
        for pattern in whitelistedPatterns {
            if path == pattern { return true }
            if pattern.hasSuffix("*") {
                let prefix = String(pattern.dropLast())
                if path.hasPrefix(prefix) { return true }
            }
        }
        return false
    }

    func addPattern(_ pattern: String) {
        guard !whitelistedPatterns.contains(pattern) else { return }
        whitelistedPatterns.append(pattern)
        saveWhitelist()
    }

    func removePattern(_ pattern: String) {
        whitelistedPatterns.removeAll { $0 == pattern }
        saveWhitelist()
    }

    func allPatterns() -> [String] {
        whitelistedPatterns
    }

    private func loadWhitelist() {
        guard let data = try? String(contentsOf: configURL, encoding: .utf8) else { return }
        whitelistedPatterns = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    private func saveWhitelist() {
        let content = whitelistedPatterns.joined(separator: "\n")
        try? FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: configURL, atomically: true, encoding: .utf8)
    }
}
