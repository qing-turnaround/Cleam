import Foundation

actor RemnantDiscoveryService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func findRemnants(for app: InstalledApp) async -> [AppRemnant] {
        var remnants: [AppRemnant] = []
        let bundleID = app.bundleIdentifier
        let appName = app.name

        let nameVariants = generateNameVariants(appName: appName, bundleID: bundleID)

        // ~/Library subdirectories to search
        let librarySearches: [(String, RemnantKind)] = [
            ("Preferences", .preferences),
            ("Caches", .caches),
            ("Application Support", .applicationSupport),
            ("Logs", .logs),
            ("Containers", .containers),
            ("Group Containers", .containers),
            ("Saved Application State", .savedState),
            ("HTTPStorages", .other),
            ("WebKit", .other),
            ("Cookies", .other),
        ]

        let library = home.appendingPathComponent("Library")

        for (subdir, kind) in librarySearches {
            let dir = library.appendingPathComponent(subdir)
            remnants.append(contentsOf: searchDirectory(dir, nameVariants: nameVariants, kind: kind))
        }

        // LaunchAgents
        let userAgents = library.appendingPathComponent("LaunchAgents")
        remnants.append(contentsOf: searchDirectory(userAgents, nameVariants: nameVariants, kind: .launchAgents))

        let systemAgents = URL(fileURLWithPath: "/Library/LaunchAgents")
        remnants.append(contentsOf: searchDirectory(systemAgents, nameVariants: nameVariants, kind: .launchAgents))

        // LaunchDaemons (system-level)
        let systemDaemons = URL(fileURLWithPath: "/Library/LaunchDaemons")
        remnants.append(contentsOf: searchDirectory(systemDaemons, nameVariants: nameVariants, kind: .launchDaemons))

        // Receipts
        let receipts = URL(fileURLWithPath: "/var/db/receipts")
        remnants.append(contentsOf: searchDirectory(receipts, nameVariants: nameVariants, kind: .receipts))

        // Crash reports
        let crashReports = library.appendingPathComponent("Logs/DiagnosticReports")
        remnants.append(contentsOf: searchDirectory(crashReports, nameVariants: nameVariants, kind: .crashReports))

        return remnants
    }

    private func generateNameVariants(appName: String, bundleID: String) -> [String] {
        var variants: [String] = []

        // Bundle ID (most reliable)
        variants.append(bundleID.lowercased())

        // Bundle ID components (e.g., "com.example.AppName" -> "appname")
        let idParts = bundleID.components(separatedBy: ".")
        if let lastPart = idParts.last {
            variants.append(lastPart.lowercased())
        }

        // App name variations
        let cleanName = appName.replacingOccurrences(of: ".app", with: "")
        variants.append(cleanName.lowercased())
        variants.append(cleanName.lowercased().replacingOccurrences(of: " ", with: ""))
        variants.append(cleanName.lowercased().replacingOccurrences(of: " ", with: "-"))
        variants.append(cleanName.lowercased().replacingOccurrences(of: " ", with: "_"))

        // Remove duplicates
        return Array(Set(variants))
    }

    private func searchDirectory(_ dir: URL, nameVariants: [String], kind: RemnantKind) -> [AppRemnant] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: []
        ) else { return [] }

        var remnants: [AppRemnant] = []

        for item in contents {
            let itemName = item.lastPathComponent.lowercased()

            let isMatch = nameVariants.contains { variant in
                itemName.contains(variant)
            }

            if isMatch {
                let size = item.isDirectory
                    ? fileManager.directorySize(at: item)
                    : fileManager.fileSize(at: item)

                remnants.append(AppRemnant(
                    path: item,
                    kind: kind,
                    sizeBytes: size
                ))
            }
        }

        return remnants
    }
}
