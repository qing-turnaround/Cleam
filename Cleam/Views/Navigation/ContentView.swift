import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            appState.ensureDirectories()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNavigation {
        case .clean:
            CleaningView()
        case .uninstall:
            UninstallView()
        case .analyze:
            DiskAnalyzerView()
        case .status:
            StatusDashboardView()
        case .optimize:
            OptimizationView()
        case .purge:
            ProjectPurgeView()
        case .settings:
            SettingsView()
        case .none:
            Text("Select a tool from the sidebar")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
