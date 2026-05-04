import Foundation

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var isSymbolicLink: Bool {
        (try? resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
    }

    var fileSize: UInt64 {
        guard let values = try? resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
              let size = values.totalFileAllocatedSize else {
            return 0
        }
        return UInt64(size)
    }

    static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static var library: URL {
        home.appendingPathComponent("Library")
    }

    static var applications: URL {
        URL(fileURLWithPath: "/Applications")
    }
}
