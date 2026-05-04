import Foundation
import AppKit

enum PermissionStatus {
    case granted
    case denied
    case unknown
}

actor PermissionService {
    func checkFullDiskAccess() -> PermissionStatus {
        let testPaths = [
            URL.home.appendingPathComponent("Library/Mail").path,
            URL.home.appendingPathComponent("Library/Safari/Bookmarks.plist").path,
        ]

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return .granted
            }
        }

        let cacheDir = URL.home.appendingPathComponent("Library/Caches").path
        if FileManager.default.isReadableFile(atPath: cacheDir) {
            return .unknown
        }

        return .denied
    }

    @MainActor
    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}
