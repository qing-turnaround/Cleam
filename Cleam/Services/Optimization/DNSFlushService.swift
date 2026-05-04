import Foundation

actor DNSFlushService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func execute() async throws -> String {
        let result = try await shell.runShell("dscacheutil -flushcache 2>&1 && sudo killall -HUP mDNSResponder 2>&1", timeout: 15)
        if result.exitCode == 0 {
            return "DNS cache flushed successfully"
        }
        // If sudo fails, try without it
        let fallback = try await shell.runShell("dscacheutil -flushcache 2>&1", timeout: 10)
        return fallback.exitCode == 0
            ? "DNS cache flushed (mDNSResponder requires admin privileges)"
            : "Failed: \(fallback.error)"
    }
}
