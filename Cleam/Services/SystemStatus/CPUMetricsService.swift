import Foundation
import Darwin

actor CPUMetricsService {
    private var previousTicks: [UInt64] = []

    func collect() -> CPUStatus {
        let logicalCores = ProcessInfo.processInfo.processorCount
        let activeProcessorCount = ProcessInfo.processInfo.activeProcessorCount

        // Load averages
        var loadAvg = [Double](repeating: 0, count: 3)
        getloadavg(&loadAvg, 3)

        // Physical cores via sysctl
        var physicalCores: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &physicalCores, &size, nil, 0)

        // CPU usage from host_processor_info
        let (overall, perCore) = getCPUUsage()

        return CPUStatus(
            overallUsage: overall,
            perCoreUsage: perCore,
            loadAverage1: loadAvg[0],
            loadAverage5: loadAvg[1],
            loadAverage15: loadAvg[2],
            physicalCores: Int(physicalCores),
            logicalCores: logicalCores
        )
    }

    private func getCPUUsage() -> (Double, [Double]) {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return (0, [])
        }

        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        var currentTicks: [UInt64] = []
        var perCore: [Double] = []
        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = UInt64(info[offset + Int(CPU_STATE_USER)])
            let system = UInt64(info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(info[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt64(info[offset + Int(CPU_STATE_NICE)])

            currentTicks.append(contentsOf: [user, system, idle, nice])

            totalUser += user + nice
            totalSystem += system
            totalIdle += idle

            if previousTicks.count == Int(numCPUs) * 4 {
                let prevOffset = i * 4
                let dUser = user + nice - previousTicks[prevOffset] - previousTicks[prevOffset + 3]
                let dSystem = system - previousTicks[prevOffset + 1]
                let dIdle = idle - previousTicks[prevOffset + 2]
                let total = dUser + dSystem + dIdle
                let usage = total > 0 ? Double(dUser + dSystem) / Double(total) * 100 : 0
                perCore.append(min(usage, 100))
            }
        }

        var overall = 0.0
        if previousTicks.count == Int(numCPUs) * 4 {
            let prevTotalUser = stride(from: 0, to: previousTicks.count, by: 4).reduce(UInt64(0)) { $0 + previousTicks[$1] + previousTicks[$1 + 3] }
            let prevTotalSystem = stride(from: 1, to: previousTicks.count, by: 4).reduce(UInt64(0)) { $0 + previousTicks[$1] }
            let prevTotalIdle = stride(from: 2, to: previousTicks.count, by: 4).reduce(UInt64(0)) { $0 + previousTicks[$1] }

            let dActive = (totalUser + totalSystem) - (prevTotalUser + prevTotalSystem)
            let dIdle = totalIdle - prevTotalIdle
            let dTotal = dActive + dIdle
            overall = dTotal > 0 ? Double(dActive) / Double(dTotal) * 100 : 0
        }

        previousTicks = currentTicks
        return (min(overall, 100), perCore)
    }
}
