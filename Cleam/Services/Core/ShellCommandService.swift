import Foundation

struct ShellResult {
    let exitCode: Int32
    let output: String
    let error: String
}

actor ShellCommandService {
    func run(_ command: String, arguments: [String] = [], timeout: TimeInterval = 30) async throws -> ShellResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            let workItem = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: workItem)

            do {
                try process.run()
                process.waitUntilExit()
                workItem.cancel()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let result = ShellResult(
                    exitCode: process.terminationStatus,
                    output: String(data: outputData, encoding: .utf8) ?? "",
                    error: String(data: errorData, encoding: .utf8) ?? ""
                )
                continuation.resume(returning: result)
            } catch {
                workItem.cancel()
                continuation.resume(throwing: error)
            }
        }
    }

    func runShell(_ command: String, timeout: TimeInterval = 30) async throws -> ShellResult {
        try await run("/bin/bash", arguments: ["-c", command], timeout: timeout)
    }
}
