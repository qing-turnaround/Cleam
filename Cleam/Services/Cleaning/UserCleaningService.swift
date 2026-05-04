import Foundation

actor UserCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let library = home.appendingPathComponent("Library")

        let targets: [(String, String, CleanRiskLevel)] = [
            ("Caches", "User Cache", .low),
            ("Logs", "User Log", .low),
            ("Cookies", "Cookie", .medium),
            ("Logs/DiagnosticReports", "Crash Report", .low),
            ("Saved Application State", "Saved State", .low),
            ("HTTPStorages", "HTTP Storage", .low),
            ("WebKit", "WebKit Data", .medium),
        ]

        for (subdir, prefix, risk) in targets {
            let dir = library.appendingPathComponent(subdir)
            items.append(contentsOf: scanSubdirectories(dir, displayPrefix: prefix, riskLevel: risk))
        }

        // Trash
        let trashURL = home.appendingPathComponent(".Trash")
        let trashSize = fileManager.directorySize(at: trashURL)
        if trashSize > 0 {
            items.append(CleanableItem(
                path: trashURL,
                displayName: "Trash",
                sizeBytes: trashSize,
                category: .userCaches,
                riskLevel: .low
            ))
        }

        // Recent items
        let recentURL = library.appendingPathComponent("Application Support/com.apple.sharedfilelist")
        let recentSize = fileManager.directorySize(at: recentURL)
        if recentSize > 1024 {
            items.append(CleanableItem(
                path: recentURL,
                displayName: "Recent Items",
                sizeBytes: recentSize,
                category: .userCaches,
                riskLevel: .low
            ))
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func scanSubdirectories(_ url: URL, displayPrefix: String, riskLevel: CleanRiskLevel) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: []
        ) else { return [] }

        var items: [CleanableItem] = []
        for item in contents {
            let size = item.isDirectory
                ? fileManager.directorySize(at: item)
                : fileManager.fileSize(at: item)
            guard size > 4096 else { continue }

            items.append(CleanableItem(
                path: item,
                displayName: "\(displayPrefix): \(item.lastPathComponent)",
                sizeBytes: size,
                modificationDate: fileManager.modificationDate(at: item),
                category: .userCaches,
                riskLevel: riskLevel
            ))
        }
        return items
    }
}
