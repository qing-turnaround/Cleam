import Foundation
import Darwin

actor ProcessMetricsService {
    private var previousSamples: [pid_t: (time: UInt64, timestamp: UInt64)] = [:]
    private var lastSampleTime: UInt64 = 0

    func collectTopProcesses(count: Int = 5) -> [TopProcess] {
        var allPIDs = [pid_t](repeating: 0, count: 1024)
        let bytesUsed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &allPIDs, Int32(allPIDs.count * MemoryLayout<pid_t>.size))
        let pidCount = Int(bytesUsed) / MemoryLayout<pid_t>.size

        let now = mach_absolute_time()
        let elapsed = lastSampleTime > 0 ? now - lastSampleTime : 0
        let coreCount = UInt64(ProcessInfo.processInfo.processorCount)

        var currentSamples: [pid_t: (time: UInt64, timestamp: UInt64)] = [:]
        var processes: [TopProcess] = []

        for i in 0..<pidCount {
            let pid = allPIDs[i]
            guard pid > 0 else { continue }

            var taskInfo = proc_taskinfo()
            let infoSize = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(MemoryLayout<proc_taskinfo>.size))
            guard infoSize > 0 else { continue }

            var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            let name = String(cString: nameBuffer)
            guard !name.isEmpty else { continue }

            let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            let memBytes = UInt64(taskInfo.pti_resident_size)

            currentSamples[pid] = (time: totalTime, timestamp: now)

            var cpuPercent = 0.0
            if elapsed > 0, let prev = previousSamples[pid] {
                let deltaTime = totalTime - prev.time
                cpuPercent = Double(deltaTime) / Double(elapsed) / Double(coreCount) * 100.0
                cpuPercent = min(max(cpuPercent, 0), Double(coreCount) * 100)
            }

            processes.append(TopProcess(
                id: pid,
                name: name,
                cpuPercent: cpuPercent,
                memoryBytes: memBytes
            ))
        }

        previousSamples = currentSamples
        lastSampleTime = now

        processes.sort { $0.cpuPercent > $1.cpuPercent }
        return Array(processes.prefix(count))
    }
}
