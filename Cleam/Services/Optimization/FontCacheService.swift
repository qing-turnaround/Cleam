import Foundation

actor FontCacheService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func rebuild() async throws -> String {
        let result = try await shell.runShell("atsutil databases -removeUser 2>&1 && atsutil server -shutdown 2>&1 && atsutil server -ping 2>&1", timeout: 30)
        return result.exitCode == 0
            ? "Font cache rebuilt successfully"
            : "Partial rebuild: \(result.output)"
    }
}
