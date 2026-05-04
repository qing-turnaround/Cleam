import Foundation

enum PathValidationError: LocalizedError {
    case notAbsolutePath
    case pathTraversal
    case criticalSystemPath
    case invalidCharacters
    case symlinkToProtectedPath
    case protectedBundle
    case whitelisted
    case emptyPath

    var errorDescription: String? {
        switch self {
        case .notAbsolutePath: return "Path must be absolute"
        case .pathTraversal: return "Path contains traversal components (..)"
        case .criticalSystemPath: return "Cannot delete critical system path"
        case .invalidCharacters: return "Path contains invalid characters"
        case .symlinkToProtectedPath: return "Symlink points to a protected path"
        case .protectedBundle: return "Path belongs to a protected application"
        case .whitelisted: return "Path is whitelisted by user"
        case .emptyPath: return "Path is empty"
        }
    }
}

actor PathValidationService {
    private let protectionList: ProtectionListService
    private let whitelist: WhitelistService

    private static let criticalPaths: Set<String> = [
        "/", "/System", "/usr", "/bin", "/sbin", "/etc", "/var",
        "/private", "/private/var", "/private/etc",
        "/Library/Apple", "/System/Library",
        "/usr/bin", "/usr/lib", "/usr/sbin", "/usr/share",
        "/Library/Apple/System",
    ]

    private static let criticalPrefixes: [String] = [
        "/System/",
        "/usr/bin/",
        "/usr/lib/",
        "/usr/sbin/",
        "/Library/Apple/",
    ]

    init(protectionList: ProtectionListService, whitelist: WhitelistService) {
        self.protectionList = protectionList
        self.whitelist = whitelist
    }

    func validate(_ url: URL) throws {
        let path = url.path

        guard !path.isEmpty else {
            throw PathValidationError.emptyPath
        }

        guard path.hasPrefix("/") else {
            throw PathValidationError.notAbsolutePath
        }

        guard !path.contains("..") else {
            throw PathValidationError.pathTraversal
        }

        let normalizedPath = (path as NSString).standardizingPath
        guard Self.criticalPaths.contains(normalizedPath) == false else {
            throw PathValidationError.criticalSystemPath
        }

        for prefix in Self.criticalPrefixes {
            if normalizedPath.hasPrefix(prefix) && normalizedPath != prefix {
                throw PathValidationError.criticalSystemPath
            }
        }

        for scalar in path.unicodeScalars {
            if scalar.value < 32 && scalar != "\t" {
                throw PathValidationError.invalidCharacters
            }
        }

        let resolved = url.resolvingSymlinksInPath().path
        if resolved != path {
            guard Self.criticalPaths.contains(resolved) == false else {
                throw PathValidationError.symlinkToProtectedPath
            }
            for prefix in Self.criticalPrefixes {
                if resolved.hasPrefix(prefix) {
                    throw PathValidationError.symlinkToProtectedPath
                }
            }
        }

        if await protectionList.isProtected(path: normalizedPath) {
            throw PathValidationError.protectedBundle
        }

        if await whitelist.isWhitelisted(path: normalizedPath) {
            throw PathValidationError.whitelisted
        }
    }
}
