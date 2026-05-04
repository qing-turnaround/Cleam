import Foundation

actor ProjectCacheCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    private let cacheDirectoryNames: Set<String> = [
        ".next", "__pycache__", ".dart_tool", ".nuxt", ".output",
        ".parcel-cache", ".cache", ".turbo", ".svelte-kit",
        ".angular", ".webpack_cache",
    ]

    func scan(rootDirectories: [URL]? = nil) async -> [CleanableItem] {
        let roots = rootDirectories ?? [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Code"),
            home.appendingPathComponent("workspace"),
            home.appendingPathComponent("repos"),
            home.appendingPathComponent("src"),
        ]

        var items: [CleanableItem] = []

        for root in roots {
            guard fileManager.fileExists(atPath: root.path) else { continue }
            await scanRecursive(root, maxDepth: 5, currentDepth: 0, items: &items)
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func scanRecursive(_ url: URL, maxDepth: Int, currentDepth: Int, items: inout [CleanableItem]) async {
        guard currentDepth < maxDepth else { return }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for item in contents {
            guard item.isDirectory else { continue }
            let name = item.lastPathComponent

            if name == "node_modules" || name == ".git" { continue }

            if cacheDirectoryNames.contains(name) {
                let size = fileManager.directorySize(at: item)
                guard size > 500_000 else { continue }

                let projectName = item.deletingLastPathComponent().lastPathComponent
                items.append(CleanableItem(
                    path: item,
                    displayName: "\(projectName)/\(name)",
                    sizeBytes: size,
                    modificationDate: fileManager.modificationDate(at: item),
                    category: .projectCaches,
                    riskLevel: .low
                ))
            } else {
                await scanRecursive(item, maxDepth: maxDepth, currentDepth: currentDepth + 1, items: &items)
            }
        }
    }
}
