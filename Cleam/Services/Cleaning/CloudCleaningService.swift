import Foundation

actor CloudCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        let targets: [(name: String, paths: [String])] = [
            ("Dropbox Cache", [".dropbox/cache", ".dropbox/crash", ".dropbox/logs"]),
            ("Google Drive Cache", [
                "Library/Caches/com.google.GoogleDrive",
                "Library/Application Support/Google/DriveFS/cachedb",
            ]),
            ("OneDrive Cache", [
                "Library/Caches/com.microsoft.OneDrive",
                "Library/Caches/com.microsoft.OneDrive.FileProvider",
                "Library/Logs/OneDrive",
            ]),
            ("iCloud Temp", ["Library/Caches/CloudKit"]),
            ("Box Cache", ["Library/Caches/com.box.desktop"]),
        ]

        for (name, paths) in targets {
            for path in paths {
                let url = home.appendingPathComponent(path)
                guard fileManager.fileExists(atPath: url.path) else { continue }

                let size = url.isDirectory
                    ? fileManager.directorySize(at: url)
                    : fileManager.fileSize(at: url)
                guard size > 100_000 else { continue }

                items.append(CleanableItem(
                    path: url,
                    displayName: name,
                    sizeBytes: size,
                    modificationDate: fileManager.modificationDate(at: url),
                    category: .cloud,
                    riskLevel: .low
                ))
            }
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
