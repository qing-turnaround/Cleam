import Foundation

actor MaintenanceService {
    private let shell: ShellCommandService

    init(shell: ShellCommandService) {
        self.shell = shell
    }

    func runDaily() async throws -> String {
        let result = try await shell.runShell("sudo periodic daily 2>&1", timeout: 120)
        return result.exitCode == 0
            ? "Daily maintenance completed"
            : "Failed: \(result.error)"
    }

    func runWeekly() async throws -> String {
        let result = try await shell.runShell("sudo periodic weekly 2>&1", timeout: 120)
        return result.exitCode == 0
            ? "Weekly maintenance completed"
            : "Failed: \(result.error)"
    }

    func runMonthly() async throws -> String {
        let result = try await shell.runShell("sudo periodic monthly 2>&1", timeout: 180)
        return result.exitCode == 0
            ? "Monthly maintenance completed"
            : "Failed: \(result.error)"
    }

    func runAll() async -> [(name: String, success: Bool, message: String)] {
        var results: [(String, Bool, String)] = []

        do {
            let msg = try await runDaily()
            results.append(("Daily", true, msg))
        } catch {
            results.append(("Daily", false, error.localizedDescription))
        }

        do {
            let msg = try await runWeekly()
            results.append(("Weekly", true, msg))
        } catch {
            results.append(("Weekly", false, error.localizedDescription))
        }

        do {
            let msg = try await runMonthly()
            results.append(("Monthly", true, msg))
        } catch {
            results.append(("Monthly", false, error.localizedDescription))
        }

        return results
    }

    func lastRunDates() async -> (daily: Date?, weekly: Date?, monthly: Date?) {
        let fm = FileManager.default
        let dailyLog = "/var/log/daily.out"
        let weeklyLog = "/var/log/weekly.out"
        let monthlyLog = "/var/log/monthly.out"

        return (
            fm.modificationDate(at: URL(fileURLWithPath: dailyLog)),
            fm.modificationDate(at: URL(fileURLWithPath: weeklyLog)),
            fm.modificationDate(at: URL(fileURLWithPath: monthlyLog))
        )
    }
}
