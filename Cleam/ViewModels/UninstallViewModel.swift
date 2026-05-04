import SwiftUI
import AppKit

@MainActor
class UninstallViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var selectedApps: Set<String> = []
    @Published var searchText = ""
    @Published var isScanning = false
    @Published var isUninstalling = false
    @Published var uninstallPlan: UninstallPlan?
    @Published var showConfirmation = false
    @Published var result: OperationResult?
    @Published var sortOrder: SortOrder = .name

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case lastUsed = "Last Used"
    }

    private let fileOps: FileOperationService
    private let shell: ShellCommandService
    private let protectionList: ProtectionListService

    init(fileOps: FileOperationService, shell: ShellCommandService, protectionList: ProtectionListService) {
        self.fileOps = fileOps
        self.shell = shell
        self.protectionList = protectionList
    }

    var filteredApps: [InstalledApp] {
        var result = apps
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .name: result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .size: result.sort { $0.sizeBytes > $1.sizeBytes }
        case .lastUsed: result.sort { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) }
        }
        return result
    }

    func scanApps() async {
        isScanning = true
        apps = []

        let applicationsURL = URL.applications
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(
            at: applicationsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            isScanning = false
            return
        }

        var discoveredApps: [InstalledApp] = []

        for url in contents where url.pathExtension == "app" {
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else { continue }

            let name = fm.displayName(atPath: url.path)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 32, height: 32)
            let size = fm.directorySize(at: url)
            let lastUsed = fm.modificationDate(at: url)
            let isProtected = await protectionList.isSystemCritical(bundleID: bundleID)
            let isDataProtected = await protectionList.isDataProtected(bundleID: bundleID)

            discoveredApps.append(InstalledApp(
                id: bundleID,
                name: name,
                path: url,
                bundleIdentifier: bundleID,
                icon: icon,
                sizeBytes: size,
                lastUsedDate: lastUsed,
                isFromHomebrew: false,
                brewCaskName: nil,
                isProtected: isProtected,
                isDataProtected: isDataProtected
            ))
        }

        apps = discoveredApps
        isScanning = false
    }

    func prepareUninstall(for appID: String) async {
        guard let app = apps.first(where: { $0.id == appID }) else { return }

        let remnants = await findRemnants(for: app)
        let isRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == app.bundleIdentifier
        }

        uninstallPlan = UninstallPlan(
            app: app,
            remnants: remnants,
            requiresSudo: false,
            isRunning: isRunning
        )
        showConfirmation = true
    }

    func executeUninstall() async {
        guard let plan = uninstallPlan else { return }
        isUninstalling = true
        let startTime = Date()

        var allURLs = [plan.app.path]
        allURLs.append(contentsOf: plan.remnants.map(\.path))

        let result = await fileOps.deleteBatch(urls: allURLs, isDryRun: false) { _, _ in }

        self.result = OperationResult(
            success: result.errors.isEmpty,
            freedBytes: result.freedBytes,
            deletedCount: result.deletedCount,
            failedCount: result.errors.count,
            errors: result.errors,
            duration: Date().timeIntervalSince(startTime)
        )

        apps.removeAll { $0.id == plan.app.id }
        showConfirmation = false
        uninstallPlan = nil
        isUninstalling = false
    }

    private func findRemnants(for app: InstalledApp) async -> [AppRemnant] {
        let fm = FileManager.default
        var remnants: [AppRemnant] = []

        let searchDirs: [(String, RemnantKind)] = [
            ("Preferences", .preferences),
            ("Caches", .caches),
            ("Application Support", .applicationSupport),
            ("Logs", .logs),
            ("Containers", .containers),
            ("Saved Application State", .savedState),
            ("HTTPStorages", .other),
            ("WebKit", .other),
        ]

        let library = URL.library

        for (subdir, kind) in searchDirs {
            let dir = library.appendingPathComponent(subdir)
            guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }

            for item in contents {
                let name = item.lastPathComponent.lowercased()
                let bundleID = app.bundleIdentifier.lowercased()
                let appName = app.name.lowercased().replacingOccurrences(of: " ", with: "")

                if name.contains(bundleID) || name.contains(appName) {
                    let size = item.isDirectory ? fm.directorySize(at: item) : fm.fileSize(at: item)
                    remnants.append(AppRemnant(path: item, kind: kind, sizeBytes: size))
                }
            }
        }

        let agentDirs = [
            library.appendingPathComponent("LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
        ]

        for dir in agentDirs {
            guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for item in contents where item.lastPathComponent.lowercased().contains(app.bundleIdentifier.lowercased()) {
                let size = fm.fileSize(at: item)
                remnants.append(AppRemnant(path: item, kind: .launchAgents, sizeBytes: size))
            }
        }

        return remnants
    }
}
