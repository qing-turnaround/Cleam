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

    private static func defaultTasks() -> [OptimizeTask] {
        [
            OptimizeTask(id: "dns_flush", name: "Flush DNS Cache", description: "Clear the DNS resolver cache to fix name resolution issues", category: .dns),
            OptimizeTask(id: "spotlight_rebuild", name: "Rebuild Spotlight Index", description: "Rebuild the Spotlight search index for faster searches", category: .spotlight, riskLevel: .medium, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "quicklook_reset", name: "Reset QuickLook Cache", description: "Clear the QuickLook thumbnail cache", category: .quicklook),
            OptimizeTask(id: "launch_services", name: "Rebuild Launch Services", description: "Fix duplicate entries in Open With menus", category: .launchServices),
            OptimizeTask(id: "sqlite_vacuum", name: "Optimize Databases", description: "VACUUM Mail, Safari, Messages SQLite databases", category: .sqlite, riskLevel: .medium, prerequisites: [.appNotRunning("Mail"), .appNotRunning("Safari")]),
            OptimizeTask(id: "font_cache", name: "Rebuild Font Cache", description: "Clear font caches to fix rendering issues", category: .fontCache),
            OptimizeTask(id: "broken_agents", name: "Clean Broken Launch Agents", description: "Find and remove broken Launch Agent plists", category: .launchAgents, riskLevel: .medium),
            OptimizeTask(id: "maintenance_daily", name: "Run Daily Maintenance", description: "Execute macOS daily periodic maintenance scripts", category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "maintenance_weekly", name: "Run Weekly Maintenance", description: "Execute macOS weekly periodic maintenance scripts", category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
            OptimizeTask(id: "maintenance_monthly", name: "Run Monthly Maintenance", description: "Execute macOS monthly periodic maintenance scripts", category: .maintenance, requiresSudo: true, prerequisites: [.sudoRequired]),
        ]
    }
}
