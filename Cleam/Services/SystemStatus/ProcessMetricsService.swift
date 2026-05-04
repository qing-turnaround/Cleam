import Foundation
import Darwin

actor ProcessMetricsService {
    func collectTopProcesses(count: Int = 5) -> [TopProcess] {
        var allPIDs = [pid_t](repeating: 0, count: 1024)
        let bytesUsed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &allPIDs, Int32(allPIDs.count * MemoryLayout<pid_t>.size))
        let pidCount = Int(bytesUsed) / MemoryLayout<pid_t>.size

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

            let memBytes = UInt64(taskInfo.pti_resident_size)

            // CPU usage approximation from task info
            let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            let cpuPercent = Double(totalTime) / 10_000_000.0 // rough approximation

            processes.append(TopProcess(
                id: pid,
                name: name,
                cpuPercent: min(cpuPercent, 100),
                memoryBytes: memBytes
            ))
        }

        // Sort by memory usage (more stable than instantaneous CPU)
        processes.sort { $0.memoryBytes > $1.memoryBytes }
        return Array(processes.prefix(count))
    }
}
