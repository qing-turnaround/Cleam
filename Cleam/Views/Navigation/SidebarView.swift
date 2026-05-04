import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    private var toolItems: [NavigationItem] {
        [.clean, .uninstall, .analyze, .status, .optimize, .purge]
    }

    var body: some View {
        List(selection: $appState.selectedNavigation) {
            Section("Tools") {
                ForEach(toolItems) { item in
                    Label(item.label, systemImage: item.icon)
                        .tag(item)
                }
            }

            Section("") {
                Label(NavigationItem.settings.label, systemImage: NavigationItem.settings.icon)
                    .tag(NavigationItem.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            FreeSpaceIndicator()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(minWidth: 200)
    }
}

struct FreeSpaceIndicator: View {
    @State private var freeSpace: UInt64 = 0
    @State private var totalSpace: UInt64 = 0

    var usagePercent: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(totalSpace - freeSpace) / Double(totalSpace) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Disk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(ByteFormatter.format(freeSpace)) free")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.sizeColor(percentage: usagePercent))
                        .frame(width: geo.size.width * min(usagePercent / 100, 1.0))
                }
            }
            .frame(height: 6)
        }
        .onAppear { refreshDiskSpace() }
    }

    private func refreshDiskSpace() {
        let fm = FileManager.default
        freeSpace = fm.diskFreeSpace()
        totalSpace = fm.diskTotalSpace()
    }
}
