import Foundation
import AppKit

actor AppDiscoveryService {
    private let fileManager = FileManager.default
    private let protectionList: ProtectionListService

    init(protectionList: ProtectionListService) {
        self.protectionList = protectionList
    }

    func discoverApps() async -> [InstalledApp] {
        var apps: [InstalledApp] = []

        let searchPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        for searchPath in searchPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: searchPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents {
                guard url.pathExtension == "app" else { continue }
                if let app = await resolveApp(at: url) {
                    apps.append(app)
                }
            }

            // Also scan subdirectories one level deep (e.g. /Applications/Utilities/)
            for url in contents {
                guard url.isDirectory, url.pathExtension != "app" else { continue }
                guard let subContents = try? fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for subURL in subContents where subURL.pathExtension == "app" {
                    if let app = await resolveApp(at: subURL) {
                        apps.append(app)
                    }
                }
            }
        }

        return apps
    }

    private func resolveApp(at url: URL) async -> InstalledApp? {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return nil }

        let name = fileManager.displayName(atPath: url.path)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)

        let size = fileManager.directorySize(at: url)
        let lastUsed = lastUsedDate(for: url)
        let isProtected = await protectionList.isSystemCritical(bundleID: bundleID)
        let isDataProtected = await protectionList.isDataProtected(bundleID: bundleID)
        let brewInfo = detectHomebrew(bundleID: bundleID, appName: name)

        return InstalledApp(
            id: bundleID,
            name: name,
            path: url,
            bundleIdentifier: bundleID,
            icon: icon,
            sizeBytes: size,
            lastUsedDate: lastUsed,
            isFromHomebrew: brewInfo.0,
            brewCaskName: brewInfo.1,
            isProtected: isProtected,
            isDataProtected: isDataProtected
        )
    }

    private func lastUsedDate(for url: URL) -> Date? {
        if let values = try? url.resourceValues(forKeys: [.contentAccessDateKey]) {
            return values.contentAccessDate
        }
        return fileManager.modificationDate(at: url)
    }

    private func detectHomebrew(bundleID: String, appName: String) -> (Bool, String?) {
        let caskroomPath = "/opt/homebrew/Caskroom"
        let altCaskroomPath = "/usr/local/Caskroom"

        let caskName = appName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".app", with: "")

        for path in [caskroomPath, altCaskroomPath] {
            let caskURL = URL(fileURLWithPath: path).appendingPathComponent(caskName)
            if fileManager.fileExists(atPath: caskURL.path) {
                return (true, caskName)
            }
        }

        return (false, nil)
    }
}
