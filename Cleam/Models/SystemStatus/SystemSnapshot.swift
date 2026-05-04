import Foundation

struct SystemSnapshot {
    let timestamp: Date
    let cpu: CPUStatus
    let memory: MemoryStatus
    let disks: [DiskStatus]
    let network: [NetworkInterfaceStatus]
    let battery: BatteryStatus?
    let topProcesses: [TopProcess]
    let healthScore: HealthScore
}

struct CPUStatus {
    let overallUsage: Double
    let perCoreUsage: [Double]
    let loadAverage1: Double
    let loadAverage5: Double
    let loadAverage15: Double
    let physicalCores: Int
    let logicalCores: Int

    static var empty: CPUStatus {
        CPUStatus(overallUsage: 0, perCoreUsage: [], loadAverage1: 0,
                  loadAverage5: 0, loadAverage15: 0, physicalCores: 0, logicalCores: 0)
    }
}

struct MemoryStatus {
    let usedBytes: UInt64
    let totalBytes: UInt64
    let swapUsedBytes: UInt64
    let swapTotalBytes: UInt64
    let fileCacheBytes: UInt64
    let pressureLevel: MemoryPressure

    var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    static var empty: MemoryStatus {
        MemoryStatus(usedBytes: 0, totalBytes: 0, swapUsedBytes: 0,
                     swapTotalBytes: 0, fileCacheBytes: 0, pressureLevel: .normal)
    }
}

enum MemoryPressure: String {
    case normal = "Normal"
    case warn = "Warning"
    case critical = "Critical"
}

struct DiskStatus: Identifiable {
    let id: String
    let name: String
    let mountPoint: String
    let totalBytes: UInt64
    let usedBytes: UInt64
    let isInternal: Bool

    var usagePercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    var freeBytes: UInt64 {
        totalBytes > usedBytes ? totalBytes - usedBytes : 0
    }
}

struct NetworkInterfaceStatus: Identifiable {
    let id: String
    let name: String
    let rxBytesPerSec: Double
    let txBytesPerSec: Double
    let ipAddress: String?
    var rxHistory: [Double]
    var txHistory: [Double]
}

struct BatteryStatus {
    let chargePercent: Double
    let isCharging: Bool
    let healthPercent: Double
    let cycleCount: Int
    let temperature: Double?
    let condition: String
    let powerWatts: Double?
    let timeRemaining: String?
}

struct TopProcess: Identifiable {
    let id: Int32
    let name: String
    let cpuPercent: Double
    let memoryBytes: UInt64
}

struct HealthScore {
    let score: Int
    let penalties: [HealthPenalty]

    var label: String {
        switch score {
        case 90...100: return "Excellent"
        case 75..<90: return "Good"
        case 50..<75: return "Fair"
        case 25..<50: return "Poor"
        default: return "Critical"
        }
    }

    static var empty: HealthScore {
        HealthScore(score: 100, penalties: [])
    }
}

struct HealthPenalty {
    let category: String
    let points: Double
    let detail: String
}
