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
        case .systemCaches: return "System-level caches, logs, and temporary files"
        case .userCaches: return "User caches, logs, cookies, and saved state"
        case .browsers: return "Safari, Chrome, Firefox, Edge, Arc browser data"
        case .developer: return "Xcode, Homebrew, npm, pip, cargo caches"
        case .applications: return "Application-specific caches and data"
        case .cloud: return "Dropbox, Google Drive, OneDrive caches"
        case .projectCaches: return "Build caches: .next, __pycache__, .dart_tool"
        }
    }
}
