import Foundation

actor MetricsCollectorService {
    private let cpuService = CPUMetricsService()
    private let memoryService = MemoryMetricsService()
    private let diskService = DiskMetricsService()
    private let networkService = NetworkMetricsService()
    private let batteryService = BatteryMetricsService()
    private let processService = ProcessMetricsService()

    private var cachedDisks: [DiskStatus]?
    private var cachedBattery: BatteryStatus?
    private var lastSlowCollect: Date?
    private let slowInterval: TimeInterval = 30

    struct HardwareInfo {
        let modelName: String
        let chipName: String
        let memoryGB: Int
        let osVersion: String
    }

    private var cachedHardware: HardwareInfo?

    func collectSnapshot() async -> SystemSnapshot {
        // Fast metrics (every call)
        let cpu = await cpuService.collect()
        let memory = await memoryService.collect()
        let network = await networkService.collect()
        let processes = await processService.collectTopProcesses()

        // Slow metrics (every 30s)
        let now = Date()
        if cachedDisks == nil || lastSlowCollect == nil || now.timeIntervalSince(lastSlowCollect!) >= slowInterval {
            cachedDisks = await diskService.collect()
            cachedBattery = await batteryService.collect()
            lastSlowCollect = now
        }

        let disks = cachedDisks ?? []
        let battery = cachedBattery

        let health = calculateHealth(cpu: cpu, memory: memory, disks: disks, battery: battery)

        return SystemSnapshot(
            timestamp: now,
            cpu: cpu,
            memory: memory,
            disks: disks,
            network: network,
            battery: battery,
            topProcesses: processes,
            healthScore: health
        )
    }

    func getHardwareInfo() async -> HardwareInfo {
        if let cached = cachedHardware { return cached }

        var modelSize = 0
        sysctlbyname("hw.model", nil, &modelSize, nil, 0)
        var model = [CChar](repeating: 0, count: modelSize)
        sysctlbyname("hw.model", &model, &modelSize, nil, 0)
        let modelName = String(cString: model)

        var brandSize = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &brandSize, nil, 0)
        var brand = [CChar](repeating: 0, count: brandSize)
        sysctlbyname("machdep.cpu.brand_string", &brand, &brandSize, nil, 0)
        let chipName = String(cString: brand)

        let memGB = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let info = HardwareInfo(
            modelName: modelName,
            chipName: chipName.isEmpty ? "Apple Silicon" : chipName,
            memoryGB: memGB,
            osVersion: osVersion
        )
        cachedHardware = info
        return info
    }

    private func calculateHealth(cpu: CPUStatus, memory: MemoryStatus, disks: [DiskStatus], battery: BatteryStatus?) -> HealthScore {
        var score = 100.0
        var penalties: [HealthPenalty] = []

        if cpu.overallUsage > 80 {
            let p = (cpu.overallUsage - 80) * 0.5
            score -= p
            penalties.append(HealthPenalty(category: "CPU", points: p, detail: "High CPU: \(Int(cpu.overallUsage))%"))
        }

        if memory.usagePercent > 85 {
            let p = (memory.usagePercent - 85) * 1.0
            score -= p
            penalties.append(HealthPenalty(category: "Memory", points: p, detail: "High memory: \(Int(memory.usagePercent))%"))
        }

        if memory.pressureLevel == .critical {
            score -= 10
            penalties.append(HealthPenalty(category: "Memory", points: 10, detail: "Critical memory pressure"))
        }

        for disk in disks where disk.usagePercent > 85 {
            let p = (disk.usagePercent - 85) * 1.5
            score -= p
            penalties.append(HealthPenalty(category: "Disk", points: p, detail: "\(disk.name): \(Int(disk.usagePercent))% full"))
        }

        if let bat = battery {
            if bat.healthPercent < 80 {
                let p = (80 - bat.healthPercent) * 0.5
                score -= p
                penalties.append(HealthPenalty(category: "Battery", points: p, detail: "Battery health: \(Int(bat.healthPercent))%"))
            }
            if bat.chargePercent < 10 && !bat.isCharging {
                score -= 5
                penalties.append(HealthPenalty(category: "Battery", points: 5, detail: "Very low battery"))
            }
        }

        return HealthScore(score: max(0, min(100, Int(score))), penalties: penalties)
    }
}
