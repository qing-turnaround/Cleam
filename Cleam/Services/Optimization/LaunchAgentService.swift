import Foundation

actor LaunchAgentService {
    private let fileManager = FileManager.default
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    struct AgentInfo: Identifiable {
        let id: String
        let path: URL
        let label: String
        let isValid: Bool
        let programPath: String?
        let errorReason: String?
    }

    func scanBrokenAgents() async -> [AgentInfo] {
        var agents: [AgentInfo] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let searchPaths = [
            home.appendingPathComponent("Library/LaunchAgents"),
            URL(fileURLWithPath: "/Library/LaunchAgents"),
        ]

        for searchPath in searchPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: searchPath,
                includingPropertiesForKeys: nil,
                options: []
            ) else { continue }

            for url in contents where url.pathExtension == "plist" {
                let info = validateAgent(at: url)
                agents.append(info)
            }
        }

        return agents
    }

    func removeBrokenAgents(_ agents: [AgentInfo]) async -> Int {
        var removed = 0
        for agent in agents where !agent.isValid {
            // Unload first
            _ = try? await shell.runShell("launchctl unload '\(agent.path.path)' 2>/dev/null", timeout: 5)

            do {
                try fileManager.trashItem(at: agent.path, resultingItemURL: nil)
                removed += 1
            } catch {
                // Skip if we can't remove it
            }
        }
        return removed
    }

    private func validateAgent(at url: URL) -> AgentInfo {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return AgentInfo(
                id: url.lastPathComponent,
                path: url,
                label: url.deletingPathExtension().lastPathComponent,
                isValid: false,
                programPath: nil,
                errorReason: "Cannot parse plist"
            )
        }

        let label = plist["Label"] as? String ?? url.deletingPathExtension().lastPathComponent
        let program = plist["Program"] as? String
        let programArgs = plist["ProgramArguments"] as? [String]
        let executablePath = program ?? programArgs?.first

        if let path = executablePath {
            if !fileManager.fileExists(atPath: path) {
                return AgentInfo(
                    id: url.lastPathComponent,
                    path: url,
                    label: label,
                    isValid: false,
                    programPath: path,
                    errorReason: "Executable not found: \(path)"
                )
            }
        }

        return AgentInfo(
            id: url.lastPathComponent,
            path: url,
            label: label,
            isValid: true,
            programPath: executablePath,
            errorReason: nil
        )
    }
}
