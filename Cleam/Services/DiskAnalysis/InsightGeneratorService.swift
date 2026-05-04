import Foundation

actor InsightGeneratorService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func generateInsights() async -> [DiskInsight] {
        var insights: [DiskInsight] = []

        // iOS Backups
        let backupsURL = home.appendingPathComponent("Library/Application Support/MobileSync/Backup")
        if fileManager.fileExists(atPath: backupsURL.path) {
            let size = fileManager.directorySize(at: backupsURL)
            if size > 1_000_000_000 { // > 1GB
                insights.append(DiskInsight(
                    name: "iOS Device Backups",
                    path: backupsURL,
                    sizeBytes: size,
                    icon: "iphone",
                    category: .iosBackups
                ))
            }
        }

        // Xcode DerivedData
        let derivedDataURL = home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        if fileManager.fileExists(atPath: derivedDataURL.path) {
            let size = fileManager.directorySize(at: derivedDataURL)
            if size > 500_000_000 {
                insights.append(DiskInsight(
                    name: "Xcode DerivedData",
                    path: derivedDataURL,
                    sizeBytes: size,
                    icon: "hammer.fill",
                    category: .devCaches
                ))
            }
        }

        // Xcode Device Support
        let deviceSupportURL = home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
        if fileManager.fileExists(atPath: deviceSupportURL.path) {
            let size = fileManager.directorySize(at: deviceSupportURL)
            if size > 1_000_000_000 {
                insights.append(DiskInsight(
                    name: "Xcode iOS Device Support",
                    path: deviceSupportURL,
                    sizeBytes: size,
                    icon: "apps.iphone",
                    category: .devCaches
                ))
            }
        }

        // Xcode Archives
        let archivesURL = home.appendingPathComponent("Library/Developer/Xcode/Archives")
        if fileManager.fileExists(atPath: archivesURL.path) {
            let size = fileManager.directorySize(at: archivesURL)
            if size > 500_000_000 {
                insights.append(DiskInsight(
                    name: "Xcode Archives",
                    path: archivesURL,
                    sizeBytes: size,
                    icon: "archivebox.fill",
                    category: .devCaches
                ))
            }
        }

        // CoreSimulator devices
        let simDevicesURL = home.appendingPathComponent("Library/Developer/CoreSimulator/Devices")
        if fileManager.fileExists(atPath: simDevicesURL.path) {
            let size = fileManager.directorySize(at: simDevicesURL)
            if size > 2_000_000_000 {
                insights.append(DiskInsight(
                    name: "iOS Simulators",
                    path: simDevicesURL,
                    sizeBytes: size,
                    icon: "ipad.landscape",
                    category: .devCaches
                ))
            }
        }

        // Old Downloads
        let downloadsURL = home.appendingPathComponent("Downloads")
        let oldDownloadsSize = await sizeOfOldFiles(in: downloadsURL, olderThanDays: 90)
        if oldDownloadsSize > 500_000_000 {
            insights.append(DiskInsight(
                name: "Old Downloads (90+ days)",
                path: downloadsURL,
                sizeBytes: oldDownloadsSize,
                icon: "arrow.down.circle.fill",
                category: .oldDownloads
            ))
        }

        // Docker images
        let dockerURL = home.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        if fileManager.fileExists(atPath: dockerURL.path) {
            let size = fileManager.directorySize(at: dockerURL)
            if size > 2_000_000_000 {
                insights.append(DiskInsight(
                    name: "Docker Data",
                    path: dockerURL,
                    sizeBytes: size,
                    icon: "shippingbox.fill",
                    category: .devCaches
                ))
            }
        }

        // Homebrew cache
        let brewCacheURL = home.appendingPathComponent("Library/Caches/Homebrew")
        if fileManager.fileExists(atPath: brewCacheURL.path) {
            let size = fileManager.directorySize(at: brewCacheURL)
            if size > 500_000_000 {
                insights.append(DiskInsight(
                    name: "Homebrew Cache",
                    path: brewCacheURL,
                    sizeBytes: size,
                    icon: "mug.fill",
                    category: .devCaches
                ))
            }
        }

        // Application caches total
        let appCachesURL = home.appendingPathComponent("Library/Caches")
        if fileManager.fileExists(atPath: appCachesURL.path) {
            let size = fileManager.directorySize(at: appCachesURL)
            if size > 2_000_000_000 {
                insights.append(DiskInsight(
                    name: "Application Caches",
                    path: appCachesURL,
                    sizeBytes: size,
                    icon: "tray.full.fill",
                    category: .appCaches
                ))
            }
        }

        return insights.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func sizeOfOldFiles(in directory: URL, olderThanDays days: Int) async -> UInt64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var totalSize: UInt64 = 0

        for url in contents {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey]),
                  let modDate = values.contentModificationDate,
                  modDate < cutoff else { continue }

            if url.isDirectory {
                totalSize += fileManager.directorySize(at: url)
            } else if let size = values.totalFileAllocatedSize {
                totalSize += UInt64(size)
            }
        }

        return totalSize
    }
}
