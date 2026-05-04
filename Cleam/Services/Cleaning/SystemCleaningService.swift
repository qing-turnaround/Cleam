import Foundation

actor SystemCleaningService {
    private let fileManager = FileManager.default

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        // System caches
        items.append(contentsOf: scanDirectory(
            URL(fileURLWithPath: "/Library/Caches"),
            category: .systemCaches,
            displayPrefix: "System Cache"
        ))

        // System logs
        items.append(contentsOf: scanDirectory(
            URL(fileURLWithPath: "/Library/Logs"),
            category: .systemCaches,
            displayPrefix: "System Log"
        ))

        // Temporary files
        items.append(contentsOf: scanDirectory(
            URL(fileURLWithPath: "/private/var/tmp"),
            category: .systemCaches,
            displayPrefix: "Temp",
            ageThresholdDays: 3
        ))

        // Var logs
        items.append(contentsOf: scanDirectory(
            URL(fileURLWithPath: "/private/var/log"),
            category: .systemCaches,
            displayPrefix: "System Log",
            filePatterns: ["*.log", "*.gz"]
        ))

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func scanDirectory(
        _ url: URL,
        category: CleanCategory,
        displayPrefix: String,
        ageThresholdDays: Int? = nil,
        filePatterns: [String]? = nil
    ) -> [CleanableItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [CleanableItem] = []
        for item in contents {
            if let patterns = filePatterns {
                let name = item.lastPathComponent
                let matches = patterns.contains { pattern in
                    let ext = String(pattern.dropFirst(2)) // remove *.
                    return name.hasSuffix(ext)
                }
                if !matches { continue }
            }

            let size = item.isDirectory
                ? fileManager.directorySize(at: item)
                : fileManager.fileSize(at: item)
            guard size > 0 else { continue }

            if let threshold = ageThresholdDays,
               let modDate = fileManager.modificationDate(at: item) {
                let days = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day ?? 0
                guard days >= threshold else { continue }
            }

            items.append(CleanableItem(
                path: item,
                displayName: "\(displayPrefix): \(item.lastPathComponent)",
                sizeBytes: size,
                modificationDate: fileManager.modificationDate(at: item),
                category: category,
                riskLevel: .low
            ))
        }
        return items
    }
}
