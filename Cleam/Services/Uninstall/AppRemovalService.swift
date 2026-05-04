import Foundation
import AppKit

actor AppRemovalService {
    private let fileOps: FileOperationService
    private let remnantDiscovery: RemnantDiscoveryService
    private let brewCask: BrewCaskService
    private let shell: ShellCommandService

    init(fileOps: FileOperationService, remnantDiscovery: RemnantDiscoveryService, brewCask: BrewCaskService, shell: ShellCommandService) {
        self.fileOps = fileOps
        self.remnantDiscovery = remnantDiscovery
        self.brewCask = brewCask
        self.shell = shell
    }

    func uninstall(app: InstalledApp, remnants: [AppRemnant], isDryRun: Bool = false) async -> OperationResult {
        let startTime = Date()
        var freedBytes: UInt64 = 0
        var deletedCount = 0
        var errors: [OperationError] = []

        // Step 1: Terminate the app if running
        await terminateApp(bundleID: app.bundleIdentifier)

        // Step 2: Try Homebrew uninstall first if applicable
        if app.isFromHomebrew, let caskName = app.brewCaskName, !isDryRun {
            let brewSuccess = await brewCask.uninstallCask(caskName)
            if brewSuccess {
                // Homebrew handled the main app, still clean remnants
            }
        }

        // Step 3: Remove the .app bundle
        do {
            let size = try await fileOps.delete(url: app.path, isDryRun: isDryRun)
            freedBytes += size
            deletedCount += 1
        } catch {
            errors.append(OperationError(path: app.path, message: error.localizedDescription))
        }

        // Step 4: Remove all remnants
        for remnant in remnants {
            do {
                let size = try await fileOps.delete(url: remnant.path, isDryRun: isDryRun)
                freedBytes += size
                deletedCount += 1
            } catch {
                errors.append(OperationError(path: remnant.path, message: error.localizedDescription))
            }
        }

        // Step 5: Clean up Login Items
        if !isDryRun {
            await removeLoginItem(bundleID: app.bundleIdentifier)
        }

        return OperationResult(
            success: errors.isEmpty,
            freedBytes: freedBytes,
            deletedCount: deletedCount,
            failedCount: errors.count,
            errors: errors,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    private func terminateApp(bundleID: String) async {
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID
        }

        for app in runningApps {
            app.terminate()
            // Wait briefly for graceful termination
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            if !app.isTerminated {
                app.forceTerminate()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private func removeLoginItem(bundleID: String) async {
        _ = try? await shell.runShell(
            "osascript -e 'tell application \"System Events\" to delete every login item whose name contains \"\(bundleID)\"' 2>/dev/null",
            timeout: 5
        )
    }
}
