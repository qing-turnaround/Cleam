import Foundation

actor AppCacheCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    private var appCacheTargets: [(name: String, bundleIDs: [String])] {
        [
            ("Slack", ["com.tinyspeck.slackmacgap"]),
            ("Discord", ["com.hnc.Discord"]),
            ("Telegram", ["ru.keepcoder.Telegram"]),
            ("WhatsApp", ["net.whatsapp.WhatsApp"]),
            ("Zoom", ["us.zoom.xos"]),
            ("Teams", ["com.microsoft.teams2", "com.microsoft.teams"]),
            ("Spotify", ["com.spotify.client"]),
            ("Music", ["com.apple.Music"]),
            ("Figma", ["com.figma.Desktop"]),
            ("Notion", ["notion.id"]),
            ("Linear", ["com.linear"]),
            ("WeChat", ["com.tencent.xinWeChat"]),
            ("QQ", ["com.tencent.qq"]),
            ("DingTalk", ["com.alibaba.DingTalkMac"]),
            ("Feishu", ["com.bytedance.lark"]),
            ("Steam", ["com.valvesoftware.steam"]),
            ("Adobe Creative Cloud", ["com.adobe.acc.AdobeCreativeCloud"]),
            ("Sketch", ["com.bohemiancoding.sketch3"]),
        ]
    }

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []
        let cachesDir = home.appendingPathComponent("Library/Caches")
        let containerDir = home.appendingPathComponent("Library/Containers")

        for (appName, bundleIDs) in appCacheTargets {
            for bundleID in bundleIDs {
                // Standard caches
                let cacheURL = cachesDir.appendingPathComponent(bundleID)
                if fileManager.fileExists(atPath: cacheURL.path) {
                    let size = fileManager.directorySize(at: cacheURL)
                    if size > 1_000_000 {
                        items.append(CleanableItem(
                            path: cacheURL,
                            displayName: "\(appName) Cache",
                            sizeBytes: size,
                            modificationDate: fileManager.modificationDate(at: cacheURL),
                            category: .applications,
                            riskLevel: .low
                        ))
                    }
                }

                // Container caches
                let containerCacheURL = containerDir
                    .appendingPathComponent(bundleID)
                    .appendingPathComponent("Data/Library/Caches")
                if fileManager.fileExists(atPath: containerCacheURL.path) {
                    let size = fileManager.directorySize(at: containerCacheURL)
                    if size > 1_000_000 {
                        items.append(CleanableItem(
                            path: containerCacheURL,
                            displayName: "\(appName) Container Cache",
                            sizeBytes: size,
                            modificationDate: fileManager.modificationDate(at: containerCacheURL),
                            category: .applications,
                            riskLevel: .low
                        ))
                    }
                }
            }
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
