import Foundation

actor BundleResolverService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func resolveBundleID(for appPath: URL) -> String? {
        Bundle(url: appPath)?.bundleIdentifier
    }

    func findAppPath(for bundleID: String) async -> URL? {
        // Try NSWorkspace first
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url
        }

        // Fallback to mdfind (Spotlight)
        if let result = try? await shell.runShell(
            "mdfind 'kMDItemCFBundleIdentifier == \"\(bundleID)\"' 2>/dev/null | head -1",
            timeout: 5
        ), !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let path = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    func appInfo(for appPath: URL) -> (name: String, bundleID: String, version: String?)? {
        guard let bundle = Bundle(url: appPath),
              let bundleID = bundle.bundleIdentifier else { return nil }

        let name = FileManager.default.displayName(atPath: appPath.path)
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String

        return (name, bundleID, version)
    }
}
