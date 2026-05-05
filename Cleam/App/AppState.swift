import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case uninstall = "Uninstall"
    case analyze = "Analyze"
    case status = "Status"
    case purge = "Purge"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .analyze: return "chart.pie"
        case .status: return "gauge.medium"
        case .purge: return "folder.badge.minus"
        case .settings: return "gear"
        }
    }

    var label: String { NSLocalizedString(rawValue, bundle: .module, comment: "") }
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedNavigation: NavigationItem? = .clean
    @Published var isDryRun: Bool = false
    @Published var isOperationRunning: Bool = false
    @Published var currentOperationDescription: String = ""

    static let appName = "Cleam"
    static let version = "1.0.0"

    var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("Cleam")
    }

    var cacheDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache")
            .appendingPathComponent("Cleam")
    }

    var logDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Cleam")
    }

    func ensureDirectories() {
        let fm = FileManager.default
        for dir in [configDirectory, cacheDirectory, logDirectory] {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
