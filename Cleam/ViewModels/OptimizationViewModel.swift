import SwiftUI

@MainActor
class OptimizationViewModel: ObservableObject {
    @Published var tasks: [OptimizeTask] = []
    @Published var isRunning = false

    private let orchestrator: OptimizationOrchestrator

    init() {
        let shell = ShellCommandService()
        self.orchestrator = OptimizationOrchestrator(shell: shell)
        self.tasks = Self.defaultTasks()
    }

    func runTask(_ taskID: String) async {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].status = .running

        let result = await orchestrator.executeTask(taskID)
        tasks[index].status = .completed(success: result.success, message: result.message)
    }

    func runAll() async {
        isRunning = true
        for task in tasks {
            await runTask(task.id)
        }
        isRunning = false
    }

    func resetAll() {
        for i in tasks.indices {
            tasks[i].status = .idle
        }
    }

    private static func L(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    private static func defaultTasks() -> [OptimizeTask] {
        [
            OptimizeTask(id: "dns_flush", name: L("Flush DNS Cache"), description: L("Clear the DNS resolver cache to fix name resolution issues"), category: .dns),
            OptimizeTask(id: "spotlight_rebuild", name: L("Rebuild Spotlight Index"), description: L("Rebuild the Spotlight search index for faster searches"), category: .spotlight, riskLevel: .medium, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "quicklook_reset", name: L("Reset QuickLook Cache"), description: L("Clear the QuickLook thumbnail cache"), category: .quicklook),
            OptimizeTask(id: "launch_services", name: L("Rebuild Launch Services"), description: L("Fix duplicate entries in Open With menus"), category: .launchServices),
            OptimizeTask(id: "sqlite_vacuum", name: L("Optimize Databases"), description: L("VACUUM Mail, Safari, Messages SQLite databases"), category: .sqlite, riskLevel: .medium, prerequisites: [.appNotRunning("Mail"), .appNotRunning("Safari")]),
            OptimizeTask(id: "font_cache", name: L("Rebuild Font Cache"), description: L("Clear font caches to fix rendering issues"), category: .fontCache),
            OptimizeTask(id: "broken_agents", name: L("Clean Broken Launch Agents"), description: L("Find and remove broken Launch Agent plists"), category: .launchAgents, riskLevel: .medium),
            OptimizeTask(id: "maintenance_daily", name: L("Run Daily Maintenance"), description: L("Execute macOS daily periodic maintenance scripts"), category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "maintenance_weekly", name: L("Run Weekly Maintenance"), description: L("Execute macOS weekly periodic maintenance scripts"), category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "maintenance_monthly", name: L("Run Monthly Maintenance"), description: L("Execute macOS monthly periodic maintenance scripts"), category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
        ]
    }
}
