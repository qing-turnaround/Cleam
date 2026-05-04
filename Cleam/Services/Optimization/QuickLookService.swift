import Foundation

actor QuickLookService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func resetCache() async throws -> String {
        let result = try await shell.runShell("qlmanage -r cache 2>&1", timeout: 15)
        return result.exitCode == 0
            ? "QuickLook cache reset successfully"
            : "Failed: \(result.error)"
    }

    func resetGenerators() async throws -> String {
        let result = try await shell.runShell("qlmanage -r 2>&1", timeout: 15)
        return result.exitCode == 0
            ? "QuickLook generators reset"
            : "Failed: \(result.error)"
    }
}
