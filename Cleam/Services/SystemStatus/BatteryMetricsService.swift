import Foundation
import IOKit.ps

actor BatteryMetricsService {
    func collect() -> BatteryStatus? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }

        let currentCapacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
        let powerSource = desc[kIOPSPowerSourceStateKey] as? String ?? ""

        let chargePercent = maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) * 100 : 0

        // Time remaining
        var timeRemaining: String? = nil
        let timeToEmpty = IOPSGetTimeRemainingEstimate()
        if timeToEmpty == kIOPSTimeRemainingUnlimited {
            timeRemaining = "Plugged In"
        } else if timeToEmpty > 0 {
            let minutes = Int(timeToEmpty) / 60
            let hours = minutes / 60
            let mins = minutes % 60
            timeRemaining = "\(hours)h \(mins)m"
        }

        // Battery health from IORegistry
        let (healthPercent, cycleCount, temperature, condition) = getBatteryHealthInfo()

        let powerWatts = desc["Wattage"] as? Double

        return BatteryStatus(
            chargePercent: chargePercent,
            isCharging: isCharging,
            healthPercent: healthPercent,
            cycleCount: cycleCount,
            temperature: temperature,
            condition: condition,
            powerWatts: powerWatts,
            timeRemaining: timeRemaining
        )
    }

    private func getBatteryHealthInfo() -> (Double, Int, Double?, String) {
        var healthPercent = 100.0
        var cycleCount = 0
        var temperature: Double? = nil
        var condition = "Normal"

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else {
            return (healthPercent, cycleCount, temperature, condition)
        }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return (healthPercent, cycleCount, temperature, condition)
        }

        if let designCapacity = dict["DesignCapacity"] as? Int,
           let maxCapacity = dict["MaxCapacity"] as? Int,
           designCapacity > 0 {
            healthPercent = Double(maxCapacity) / Double(designCapacity) * 100
        }

        if let cycles = dict["CycleCount"] as? Int {
            cycleCount = cycles
        }

        if let temp = dict["Temperature"] as? Int {
            temperature = Double(temp) / 100.0
        }

        if let batteryCondition = dict["BatteryCondition"] as? String {
            condition = batteryCondition
        } else if healthPercent < 80 {
            condition = "Service Recommended"
        }

        return (healthPercent, cycleCount, temperature, condition)
    }
}
