import Foundation

actor LaunchServicesService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func rebuild() async throws -> String {
        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        let result = try await shell.runShell("\(lsregister) -kill -r -domain local -domain system -domain user 2>&1", timeout: 60)
        return result.exitCode == 0
            ? "Launch Services database rebuilt successfully"
            : "Failed: \(result.error)"
    }

    func garbageCollect() async throws -> String {
        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        let result = try await shell.runShell("\(lsregister) -gc 2>&1", timeout: 30)
        return result.exitCode == 0
            ? "Launch Services garbage collection completed"
            : "Failed: \(result.error)"
    }
}
