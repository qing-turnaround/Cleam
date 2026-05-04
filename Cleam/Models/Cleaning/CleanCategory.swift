import Foundation

enum CleanCategory: String, CaseIterable, Identifiable, Codable {
    case systemCaches = "System Caches"
    case userCaches = "User Caches"
    case browsers = "Browsers"
    case developer = "Developer"
    case applications = "Applications"
    case cloud = "Cloud Services"
    case projectCaches = "Project Caches"

    var id: String { rawValue }

    var localizedName: String { NSLocalizedString(rawValue, bundle: .module, comment: "") }

    var icon: String {
        switch self {
        case .systemCaches: return "desktopcomputer"
        case .userCaches: return "person.fill"
        case .browsers: return "globe"
        case .developer: return "hammer.fill"
        case .applications: return "app.fill"
        case .cloud: return "cloud.fill"
        case .projectCaches: return "folder.fill"
        }
    }

    var description: String {
        switch self {
        case .systemCaches: return NSLocalizedString("System-level caches, logs, and temporary files", bundle: .module, comment: "")
        case .userCaches: return NSLocalizedString("User caches, logs, cookies, and saved state", bundle: .module, comment: "")
        case .browsers: return NSLocalizedString("Safari, Chrome, Firefox, Edge, Arc browser data", bundle: .module, comment: "")
        case .developer: return NSLocalizedString("Xcode, Homebrew, npm, pip, cargo caches", bundle: .module, comment: "")
        case .applications: return NSLocalizedString("Application-specific caches and data", bundle: .module, comment: "")
        case .cloud: return NSLocalizedString("Dropbox, Google Drive, OneDrive caches", bundle: .module, comment: "")
        case .projectCaches: return NSLocalizedString("Build caches: .next, __pycache__, .dart_tool", bundle: .module, comment: "")
        }
    }
}
