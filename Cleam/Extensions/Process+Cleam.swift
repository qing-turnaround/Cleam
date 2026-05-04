import Foundation

extension Process {
    static func runSync(_ command: String, arguments: [String] = [], timeout: TimeInterval = 30) -> (output: String, error: String, exitCode: Int32) {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            return (
                String(data: outputData, encoding: .utf8) ?? "",
                String(data: errorData, encoding: .utf8) ?? "",
                process.terminationStatus
            )
        } catch {
            return ("", error.localizedDescription, -1)
        }
    }
}
