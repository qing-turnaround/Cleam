import Foundation

actor OptimizationOrchestrator {
    private let dnsService: DNSFlushService
    private let spotlightService: SpotlightService
    private let quickLookService: QuickLookService
    private let launchServicesService: LaunchServicesService
    private let sqliteService: SQLiteVacuumService
    private let fontCacheService: FontCacheService
    private let launchAgentService: LaunchAgentService
    private let maintenanceService: MaintenanceService

    init(shell: ShellCommandService) {
        self.dnsService = DNSFlushService(shell: shell)
        self.spotlightService = SpotlightService(shell: shell)
        self.quickLookService = QuickLookService(shell: shell)
        self.launchServicesService = LaunchServicesService(shell: shell)
        self.sqliteService = SQLiteVacuumService(shell: shell)
        self.fontCacheService = FontCacheService(shell: shell)
        self.launchAgentService = LaunchAgentService(shell: shell)
        self.maintenanceService = MaintenanceService(shell: shell)
    }

    func executeTask(_ taskID: String) async -> (success: Bool, message: String) {
        do {
            switch taskID {
            case "dns_flush":
                let msg = try await dnsService.execute()
                return (true, msg)

            case "spotlight_rebuild":
                let msg = try await spotlightService.rebuild()
                return (true, msg)

            case "quicklook_reset":
                let msg = try await quickLookService.resetCache()
                return (true, msg)

            case "launch_services":
                let msg = try await launchServicesService.rebuild()
                return (true, msg)

            case "sqlite_vacuum":
                let results = await sqliteService.vacuumAll()
                let successCount = results.filter(\.1).count
                return (successCount > 0, "\(successCount)/\(results.count) databases optimized")

            case "font_cache":
                let msg = try await fontCacheService.rebuild()
                return (true, msg)

            case "broken_agents":
                let agents = await launchAgentService.scanBrokenAgents()
                let broken = agents.filter { !$0.isValid }
                if broken.isEmpty {
                    return (true, "No broken Launch Agents found")
                }
                let removed = await launchAgentService.removeBrokenAgents(broken)
                return (true, "Removed \(removed) broken Launch Agents")

            case "maintenance_daily":
                let msg = try await maintenanceService.runDaily()
                return (true, msg)

            case "maintenance_weekly":
                let msg = try await maintenanceService.runWeekly()
                return (true, msg)

            case "maintenance_monthly":
                let msg = try await maintenanceService.runMonthly()
                return (true, msg)

            default:
                return (false, "Unknown task: \(taskID)")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
