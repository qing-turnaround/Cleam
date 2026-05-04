import Foundation

actor BrewCaskService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func isHomebrewInstalled() async -> Bool {
        let result = try? await shell.runShell("which brew 2>/dev/null", timeout: 5)
        return result?.exitCode == 0
    }

    func listInstalledCasks() async -> [String] {
        guard let result = try? await shell.runShell("brew list --cask 2>/dev/null", timeout: 10) else {
            return []
        }
        return result.output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func uninstallCask(_ caskName: String) async -> Bool {
        guard let result = try? await shell.runShell(
            "brew uninstall --cask \(caskName) 2>&1",
            timeout: 60
        ) else { return false }
        return result.exitCode == 0
    }

    func caskInfo(_ caskName: String) async -> (name: String, version: String, installed: Bool)? {
        guard let result = try? await shell.runShell(
            "brew info --cask --json=v2 \(caskName) 2>/dev/null",
            timeout: 10
        ), result.exitCode == 0 else { return nil }

        guard let data = result.output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let casks = json["casks"] as? [[String: Any]],
              let cask = casks.first else { return nil }

        let name = cask["name"] as? [String]
        let version = cask["version"] as? String ?? "unknown"
        let installed = cask["installed"] as? String

        return (name?.first ?? caskName, version, installed != nil)
    }
}
