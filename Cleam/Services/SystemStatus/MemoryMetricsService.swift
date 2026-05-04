import Foundation
import Darwin

actor MemoryMetricsService {
    func collect() -> MemoryStatus {
        let totalBytes = UInt64(ProcessInfo.processInfo.physicalMemory)

        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return .empty
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let fileBacked = UInt64(vmStats.external_page_count) * pageSize

        let usedBytes = active + wired + compressed

        // Swap info
        var swapUsed: UInt64 = 0
        var swapTotal: UInt64 = 0
        var xswUsage = xsw_usage()
        var xswSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &xswUsage, &xswSize, nil, 0) == 0 {
            swapUsed = xswUsage.xsu_used
            swapTotal = xswUsage.xsu_total
        }

        let usagePct = Double(usedBytes) / Double(totalBytes) * 100
        let pressure: MemoryPressure
        if usagePct > 90 { pressure = .critical }
        else if usagePct > 75 { pressure = .warn }
        else { pressure = .normal }

        return MemoryStatus(
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            swapUsedBytes: swapUsed,
            swapTotalBytes: swapTotal,
            fileCacheBytes: fileBacked,
            pressureLevel: pressure
        )
    }
}
