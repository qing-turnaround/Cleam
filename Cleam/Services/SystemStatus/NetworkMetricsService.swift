import Foundation
import Darwin

actor NetworkMetricsService {
    private var previousBytes: [String: (rx: UInt64, tx: UInt64)] = [:]
    private var previousTimestamp: Date?
    private var rxHistory: [String: RingBuffer<Double>] = [:]
    private var txHistory: [String: RingBuffer<Double>] = [:]

    func collect() -> [NetworkInterfaceStatus] {
        let currentBytes = getInterfaceBytes()
        let now = Date()
        var interfaces: [NetworkInterfaceStatus] = []

        let elapsed = previousTimestamp.map { now.timeIntervalSince($0) } ?? 1.0

        for (name, current) in currentBytes {
            var rxRate = 0.0
            var txRate = 0.0

            if let prev = previousBytes[name], elapsed > 0 {
                rxRate = Double(current.rx - prev.rx) / elapsed
                txRate = Double(current.tx - prev.tx) / elapsed

                if rxRate < 0 { rxRate = 0 }
                if txRate < 0 { txRate = 0 }
            }

            if rxHistory[name] == nil {
                rxHistory[name] = RingBuffer<Double>(capacity: 120, defaultValue: 0)
                txHistory[name] = RingBuffer<Double>(capacity: 120, defaultValue: 0)
            }
            rxHistory[name]?.append(rxRate)
            txHistory[name]?.append(txRate)

            interfaces.append(NetworkInterfaceStatus(
                id: name,
                name: name,
                rxBytesPerSec: rxRate,
                txBytesPerSec: txRate,
                ipAddress: getIPAddress(for: name),
                rxHistory: rxHistory[name]?.elements ?? [],
                txHistory: txHistory[name]?.elements ?? []
            ))
        }

        previousBytes = currentBytes
        previousTimestamp = now

        return interfaces.sorted { $0.id < $1.id }
    }

    private func getInterfaceBytes() -> [String: (rx: UInt64, tx: UInt64)] {
        var results: [String: (rx: UInt64, tx: UInt64)] = [:]

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return results }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)

            // Only track en* (Ethernet/WiFi) and lo0 (loopback)
            if name.hasPrefix("en") || name == "lo0" {
                if addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    addr.pointee.ifa_data.withMemoryRebound(to: if_data.self, capacity: 1) { data in
                        let rx = UInt64(data.pointee.ifi_ibytes)
                        let tx = UInt64(data.pointee.ifi_obytes)
                        if let existing = results[name] {
                            results[name] = (existing.rx + rx, existing.tx + tx)
                        } else {
                            results[name] = (rx, tx)
                        }
                    }
                }
            }

            ptr = addr.pointee.ifa_next
        }

        return results
    }

    private func getIPAddress(for interfaceName: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            if name == interfaceName && addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    addr.pointee.ifa_addr,
                    socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil, 0,
                    NI_NUMERICHOST
                )
                return String(cString: hostname)
            }
            ptr = addr.pointee.ifa_next
        }
        return nil
    }
}
