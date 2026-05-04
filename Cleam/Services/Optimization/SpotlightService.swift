import Foundation

actor SpotlightService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func rebuild() async throws -> String {
        let result = try await shell.runShell("sudo mdutil -E / 2>&1", timeout: 30)
        return result.exitCode == 0
            ? "Spotlight index rebuild initiated"
            : "Failed: \(result.error). Requires admin privileges."
    }

    func status() async -> String {
        guard let result = try? await shell.runShell("mdutil -s / 2>&1", timeout: 10) else {
            return "Unknown"
        }
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func disable(volume: String = "/") async throws -> String {
        let result = try await shell.runShell("sudo mdutil -i off \(volume) 2>&1", timeout: 15)
        return result.exitCode == 0 ? "Spotlight disabled for \(volume)" : "Failed: \(result.error)"
    }

    func enable(volume: String = "/") async throws -> String {
        let result = try await shell.runShell("sudo mdutil -i on \(volume) 2>&1", timeout: 15)
        return result.exitCode == 0 ? "Spotlight enabled for \(volume)" : "Failed: \(result.error)"
    }
}
