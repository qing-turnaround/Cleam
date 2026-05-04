import SwiftUI

struct StatusDashboardView: View {
    @StateObject private var viewModel: SystemStatusViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    init() {
        _viewModel = StateObject(wrappedValue: SystemStatusViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let snapshot = viewModel.snapshot {
                    headerView(snapshot)

                    LazyVGrid(columns: columns, spacing: 16) {
                        CPUCardView(cpu: snapshot.cpu)
                        MemoryCardView(memory: snapshot.memory)

                        ForEach(snapshot.disks) { disk in
                            DiskCardView(disk: disk)
                        }

                        if !snapshot.network.isEmpty {
                            NetworkCardView(interfaces: snapshot.network)
                        }

                        if let battery = snapshot.battery {
                            BatteryCardView(battery: battery)
                        }

                        ProcessCardView(processes: snapshot.topProcesses)
                    }
                } else {
                    ProgressView("Collecting system metrics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(20)
        }
        .navigationTitle("System Status")
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
    }

    private func headerView(_ snapshot: SystemSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Host.current().localizedName ?? "Mac")
                    .font(.title2)
                    .fontWeight(.semibold)
                if !viewModel.hardwareInfo.isEmpty {
                    Text(viewModel.hardwareInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HealthBadgeView(score: snapshot.healthScore)
        }
    }
}

// MARK: - Card Views

struct StatusCard<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CPUCardView: View {
    let cpu: CPUStatus

    var body: some View {
        StatusCard(title: "CPU", icon: "cpu") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.1f%%", cpu.overallUsage))
                        .font(.title)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                    Spacer()
                }

                ProgressBarView(value: cpu.overallUsage, height: 10, showLabel: false)

                HStack(spacing: 16) {
                    MetricLabel(title: "Load 1m", value: String(format: "%.2f", cpu.loadAverage1))
                    MetricLabel(title: "Load 5m", value: String(format: "%.2f", cpu.loadAverage5))
                    MetricLabel(title: "Load 15m", value: String(format: "%.2f", cpu.loadAverage15))
                }

                Text("\(cpu.physicalCores) cores / \(cpu.logicalCores) threads")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MemoryCardView: View {
    let memory: MemoryStatus

    var body: some View {
        StatusCard(title: "Memory", icon: "memorychip") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.1f%%", memory.usagePercent))
                        .font(.title)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(ByteFormatter.format(memory.usedBytes)) / \(ByteFormatter.format(memory.totalBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressBarView(value: memory.usagePercent, height: 10, showLabel: false)

                HStack(spacing: 16) {
                    MetricLabel(title: "Swap", value: ByteFormatter.format(memory.swapUsedBytes))
                    MetricLabel(title: "Cache", value: ByteFormatter.format(memory.fileCacheBytes))
                    MetricLabel(title: "Pressure", value: memory.pressureLevel.localizedName)
                }
            }
        }
    }
}

struct DiskCardView: View {
    let disk: DiskStatus

    var body: some View {
        StatusCard(title: LocalizedStringKey(disk.name), icon: "internaldrive.fill") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.1f%%", disk.usagePercent))
                        .font(.title)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(ByteFormatter.format(disk.freeBytes)) free")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressBarView(value: disk.usagePercent, height: 10, showLabel: false)

                Text("\(ByteFormatter.format(disk.usedBytes)) used of \(ByteFormatter.format(disk.totalBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct NetworkCardView: View {
    let interfaces: [NetworkInterfaceStatus]

    var body: some View {
        StatusCard(title: "Network", icon: "network") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(interfaces) { iface in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(iface.name)
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text(ByteFormatter.format(UInt64(iface.rxBytesPerSec)) + "/s")
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                Text(ByteFormatter.format(UInt64(iface.txBytesPerSec)) + "/s")
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                        }

                        if !iface.rxHistory.isEmpty {
                            HStack(spacing: 4) {
                                SparklineView(data: iface.rxHistory, color: .green, height: 20)
                                SparklineView(data: iface.txHistory, color: .blue, height: 20)
                            }
                        }

                        if let ip = iface.ipAddress, !ip.isEmpty {
                            Text(ip)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct BatteryCardView: View {
    let battery: BatteryStatus

    var body: some View {
        StatusCard(title: "Battery", icon: "battery.100") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.0f%%", battery.chargePercent))
                        .font(.title)
                        .monospacedDigit()
                        .fontWeight(.semibold)

                    if battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.green)
                    }

                    Spacer()
                }

                ProgressBarView(value: battery.chargePercent, height: 10, showLabel: false)

                HStack(spacing: 16) {
                    MetricLabel(title: "Health", value: String(format: "%.0f%%", battery.healthPercent))
                    MetricLabel(title: "Cycles", value: "\(battery.cycleCount)")
                    MetricLabel(title: "Status", value: battery.condition)
                }
            }
        }
    }
}

struct ProcessCardView: View {
    let processes: [TopProcess]

    var body: some View {
        StatusCard(title: "Top Processes", icon: "list.number") {
            VStack(spacing: 6) {
                HStack {
                    Text("Name")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("CPU")
                        .frame(width: 50, alignment: .trailing)
                    Text("Memory")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                ForEach(processes) { proc in
                    HStack {
                        Text(proc.name)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f%%", proc.cpuPercent))
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                        Text(ByteFormatter.format(proc.memoryBytes))
                            .monospacedDigit()
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                }
            }
        }
    }
}

struct HealthBadgeView: View {
    let score: HealthScore

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.healthColor(score: score.score).opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: Double(score.score) / 100)
                    .stroke(Color.healthColor(score: score.score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(score.score)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            Text(score.label)
                .font(.caption)
                .foregroundStyle(Color.healthColor(score: score.score))
        }
    }
}

struct MetricLabel: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .monospacedDigit()
        }
    }
}
