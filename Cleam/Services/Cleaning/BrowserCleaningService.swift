import Foundation

actor BrowserCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    struct BrowserProfile {
        let name: String
        let cachePaths: [String]
        let historyPaths: [String]
        let cookiePaths: [String]
    }

    private var browsers: [BrowserProfile] {
        let lib = "Library"
        return [
            BrowserProfile(
                name: "Safari",
                cachePaths: ["\(lib)/Caches/com.apple.Safari", "\(lib)/Caches/com.apple.Safari.SafeBrowsing"],
                historyPaths: [],
                cookiePaths: ["\(lib)/Cookies/com.apple.Safari.cookies"]
            ),
            BrowserProfile(
                name: "Chrome",
                cachePaths: ["\(lib)/Caches/Google/Chrome", "\(lib)/Caches/Google/Chrome/Default/Cache"],
                historyPaths: ["\(lib)/Application Support/Google/Chrome/Default/History"],
                cookiePaths: ["\(lib)/Application Support/Google/Chrome/Default/Cookies"]
            ),
            BrowserProfile(
                name: "Firefox",
                cachePaths: ["\(lib)/Caches/Firefox"],
                historyPaths: [],
                cookiePaths: []
            ),
            BrowserProfile(
                name: "Edge",
                cachePaths: ["\(lib)/Caches/com.microsoft.edgemac", "\(lib)/Caches/Microsoft Edge"],
                historyPaths: [],
                cookiePaths: []
            ),
            BrowserProfile(
                name: "Arc",
                cachePaths: ["\(lib)/Caches/company.thebrowser.Browser"],
                historyPaths: [],
                cookiePaths: []
            ),
            BrowserProfile(
                name: "Brave",
                cachePaths: ["\(lib)/Caches/BraveSoftware/Brave-Browser"],
                historyPaths: [],
                cookiePaths: []
            ),
            BrowserProfile(
                name: "Opera",
                cachePaths: ["\(lib)/Caches/com.operasoftware.Opera"],
                historyPaths: [],
                cookiePaths: []
            ),
            BrowserProfile(
                name: "Vivaldi",
                cachePaths: ["\(lib)/Caches/com.vivaldi.Vivaldi"],
                historyPaths: [],
                cookiePaths: []
            ),
        ]
    }

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        for browser in browsers {
            for cachePath in browser.cachePaths {
                let url = home.appendingPathComponent(cachePath)
                let size = fileManager.directorySize(at: url)
                guard size > 0 else { continue }

                items.append(CleanableItem(
                    path: url,
                    displayName: "\(browser.name) Cache",
                    sizeBytes: size,
                    modificationDate: fileManager.modificationDate(at: url),
                    category: .browsers,
                    riskLevel: .low
                ))
            }

            for histPath in browser.historyPaths {
                let url = home.appendingPathComponent(histPath)
                let size = fileManager.fileSize(at: url)
                guard size > 0 else { continue }

                items.append(CleanableItem(
                    path: url,
                    displayName: "\(browser.name) History",
                    sizeBytes: size,
                    category: .browsers,
                    riskLevel: .medium
                ))
            }

            for cookiePath in browser.cookiePaths {
                let url = home.appendingPathComponent(cookiePath)
                let size = url.isDirectory
                    ? fileManager.directorySize(at: url)
                    : fileManager.fileSize(at: url)
                guard size > 0 else { continue }

                items.append(CleanableItem(
                    path: url,
                    displayName: "\(browser.name) Cookies",
                    sizeBytes: size,
                    category: .browsers,
                    riskLevel: .high
                ))
            }
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
