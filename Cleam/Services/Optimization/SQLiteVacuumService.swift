import Foundation
import AppKit

actor SQLiteVacuumService {
    private let shell: ShellCommandService
    private let home = FileManager.default.homeDirectoryForCurrentUser

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    struct VacuumTarget {
        let name: String
        let dbPath: String
        let prerequisiteApp: String?
    }

    private var targets: [VacuumTarget] {
        [
            VacuumTarget(name: "Mail", dbPath: "Library/Mail/V*/MailData/Envelope Index", prerequisiteApp: "Mail"),
            VacuumTarget(name: "Safari History", dbPath: "Library/Safari/History.db", prerequisiteApp: "Safari"),
            VacuumTarget(name: "Messages", dbPath: "Library/Messages/chat.db", prerequisiteApp: "Messages"),
            VacuumTarget(name: "Photos", dbPath: "Library/Photos/Libraries/Photos Library.photoslibrary/database/Photos.sqlite", prerequisiteApp: "Photos"),
            VacuumTarget(name: "Quarantine Events", dbPath: "Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2", prerequisiteApp: nil),
        ]
    }

    func vacuumAll() async -> [(name: String, success: Bool, message: String)] {
        var results: [(String, Bool, String)] = []

        for target in targets {
            let dbURL = home.appendingPathComponent(target.dbPath)

            // Check if app is running (prerequisite)
            if let app = target.prerequisiteApp, isAppRunning(app) {
                results.append((target.name, false, "Close \(app) first"))
                continue
            }

            // Find actual db files (handle glob patterns)
            let dbPaths = expandPath(target.dbPath)

            for path in dbPaths {
                guard FileManager.default.fileExists(atPath: path) else { continue }

                let sizeBefore = FileManager.default.fileSize(at: URL(fileURLWithPath: path))

                do {
                    let result = try await shell.runShell("sqlite3 '\(path)' 'VACUUM;' 2>&1", timeout: 60)
                    if result.exitCode == 0 {
                        let sizeAfter = FileManager.default.fileSize(at: URL(fileURLWithPath: path))
                        let saved = sizeBefore > sizeAfter ? sizeBefore - sizeAfter : 0
                        results.append((target.name, true, "Freed \(ByteFormatter.format(saved))"))
                    } else {
                        results.append((target.name, false, result.error))
                    }
                } catch {
                    results.append((target.name, false, error.localizedDescription))
                }
            }
        }

        return results
    }

    private func isAppRunning(_ appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.localizedName == appName
        }
    }

    private func expandPath(_ pattern: String) -> [String] {
        let fullPattern = home.appendingPathComponent(pattern).path

        if !fullPattern.contains("*") {
            return [fullPattern]
        }

        // Simple glob expansion
        let parts = fullPattern.components(separatedBy: "/")
        var current = ["/"]

        for part in parts.dropFirst() {
            if part.contains("*") {
                var next: [String] = []
                for base in current {
                    let baseURL = URL(fileURLWithPath: base)
                    guard let contents = try? FileManager.default.contentsOfDirectory(
                        at: baseURL,
                        includingPropertiesForKeys: nil
                    ) else { continue }
                    for item in contents {
                        next.append(item.path)
                    }
                }
                current = next
            } else {
                current = current.map { $0 + "/" + part }
            }
        }

        return current.filter { FileManager.default.fileExists(atPath: $0) }
    }
}
