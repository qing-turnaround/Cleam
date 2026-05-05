import SwiftUI
import UniformTypeIdentifiers

enum StatusPanel: String, CaseIterable, Codable, Identifiable {
    case cpu, memory, disk, network, battery, processes

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .disk: return "Disk"
        case .network: return "Network"
        case .battery: return "Battery"
        case .processes: return "Top Processes"
        }
    }

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive.fill"
        case .network: return "network"
        case .battery: return "battery.100"
        case .processes: return "list.number"
        }
    }
}

struct StatusDashboardView: View {
    @StateObject private var viewModel: SystemStatusViewModel
    @State private var panelOrder: [StatusPanel] = StatusDashboardView.loadPanelOrder()
    @State private var draggingPanel: StatusPanel?

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
                        ForEach(visiblePanels(for: snapshot)) { panel in
                            panelView(panel, snapshot: snapshot)
                                .opacity(draggingPanel == panel ? 0.4 : 1.0)
                                .onDrag {
                                    draggingPanel = panel
                                    return NSItemProvider(object: panel.rawValue as NSString)
                                }
                                .onDrop(of: [.text], delegate: PanelDropDelegate(
                                    panel: panel,
                                    panelOrder: $panelOrder,
                                    draggingPanel: $draggingPanel,
                                    onReorder: savePanelOrder
                                ))
                        }
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

    private func visiblePanels(for snapshot: SystemSnapshot) -> [StatusPanel] {
        panelOrder.filter { panel in
            switch panel {
            case .cpu, .memory, .processes: return true
            case .disk: return !snapshot.disks.isEmpty
            case .network: return !snapshot.network.isEmpty
            case .battery: return snapshot.battery != nil
            }
        }
    }

    @ViewBuilder
    private func panelView(_ panel: StatusPanel, snapshot: SystemSnapshot) -> some View {
        switch panel {
        case .cpu:
            CPUCardView(cpu: snapshot.cpu)
        case .memory:
            MemoryCardView(memory: snapshot.memory)
        case .disk:
            DiskCardView(disks: snapshot.disks)
        case .network:
            NetworkCardView(interfaces: snapshot.network)
        case .battery:
            if let battery = snapshot.battery {
                BatteryCardView(battery: battery)
            }
        case .processes:
            ProcessCardView(processes: snapshot.topProcesses)
        }
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

    private func savePanelOrder() {
        if let data = try? JSONEncoder().encode(panelOrder) {
            UserDefaults.standard.set(data, forKey: "StatusPanelOrder")
        }
    }

    static func loadPanelOrder() -> [StatusPanel] {
        guard let data = UserDefaults.standard.data(forKey: "StatusPanelOrder"),
              let order = try? JSONDecoder().decode([StatusPanel].self, from: data),
              !order.isEmpty else {
            return [.cpu, .memory, .disk, .network, .battery, .processes]
        }
        let knownPanels = Set(StatusPanel.allCases)
        let decoded = order.filter { knownPanels.contains($0) }
        let missing = StatusPanel.allCases.filter { !decoded.contains($0) }
        return decoded + missing
    }
}

struct PanelDropDelegate: DropDelegate {
    let panel: StatusPanel
    @Binding var panelOrder: [StatusPanel]
    @Binding var draggingPanel: StatusPanel?
    let onReorder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingPanel = nil
        onReorder()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingPanel, dragging != panel else { return }
        guard let fromIndex = panelOrder.firstIndex(of: dragging),
              let toIndex = panelOrder.firstIndex(of: panel) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            panelOrder.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
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
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(minHeight: 160)
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
    let disks: [DiskStatus]

    var body: some View {
        StatusCard(title: "Disk", icon: "internaldrive.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(disks) { disk in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(disk.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(ByteFormatter.format(disk.freeBytes)) free")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProgressBarView(value: disk.usagePercent, height: 8, showLabel: false)

                        Text("\(ByteFormatter.format(disk.usedBytes)) used of \(ByteFormatter.format(disk.totalBytes))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
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
