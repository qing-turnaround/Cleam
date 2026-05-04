import SwiftUI
import Combine

@MainActor
class SystemStatusViewModel: ObservableObject {
    @Published var snapshot: SystemSnapshot?
    @Published var isCollecting = false
    @Published var hardwareInfo: String = ""

    private var timer: AnyCancellable?
    private let metricsCollector = MetricsCollectorService()

    func startMonitoring() {
        isCollecting = true
        Task {
            let hw = await metricsCollector.getHardwareInfo()
            hardwareInfo = "\(hw.modelName) · \(hw.chipName) · \(hw.memoryGB) GB · \(hw.osVersion)"
            await collectMetrics()
        }
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.collectMetrics() }
            }
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        isCollecting = false
    }

    private func collectMetrics() async {
        snapshot = await metricsCollector.collectSnapshot()
    }
}
