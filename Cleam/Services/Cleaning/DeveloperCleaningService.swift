import Foundation

actor DeveloperCleaningService {
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser

    struct DevTarget {
        let name: String
        let paths: [String]
        let riskLevel: CleanRiskLevel
    }

    private var targets: [DevTarget] {
        [
            // Xcode
            DevTarget(name: "Xcode DerivedData", paths: ["Library/Developer/Xcode/DerivedData"], riskLevel: .low),
            DevTarget(name: "Xcode Archives", paths: ["Library/Developer/Xcode/Archives"], riskLevel: .medium),
            DevTarget(name: "Xcode Device Support", paths: ["Library/Developer/Xcode/iOS DeviceSupport"], riskLevel: .low),
            DevTarget(name: "Xcode Simulators Cache", paths: ["Library/Developer/CoreSimulator/Caches"], riskLevel: .low),
            DevTarget(name: "Xcode Previews", paths: ["Library/Developer/Xcode/UserData/Previews"], riskLevel: .low),
            DevTarget(name: "Xcode Documentation Cache", paths: ["Library/Caches/com.apple.dt.documentation"], riskLevel: .low),

            // CocoaPods
            DevTarget(name: "CocoaPods Cache", paths: ["Library/Caches/CocoaPods"], riskLevel: .low),

            // Homebrew
            DevTarget(name: "Homebrew Cache", paths: ["Library/Caches/Homebrew"], riskLevel: .low),

            // Node.js
            DevTarget(name: "npm Cache", paths: [".npm/_cacache", ".npm/_logs"], riskLevel: .low),
            DevTarget(name: "Yarn Cache", paths: ["Library/Caches/Yarn"], riskLevel: .low),
            DevTarget(name: "pnpm Store", paths: ["Library/pnpm/store"], riskLevel: .low),
            DevTarget(name: "Bun Cache", paths: [".bun/install/cache"], riskLevel: .low),

            // Python
            DevTarget(name: "pip Cache", paths: ["Library/Caches/pip"], riskLevel: .low),
            DevTarget(name: "Poetry Cache", paths: ["Library/Caches/pypoetry"], riskLevel: .low),
            DevTarget(name: "Conda Packages", paths: [".conda/pkgs"], riskLevel: .low),

            // Rust
            DevTarget(name: "Cargo Registry", paths: [".cargo/registry"], riskLevel: .low),
            DevTarget(name: "Cargo Git DB", paths: [".cargo/git/db"], riskLevel: .low),
            DevTarget(name: "Rustup Toolchains", paths: [".rustup/toolchains"], riskLevel: .medium),

            // Go
            DevTarget(name: "Go Module Cache", paths: ["go/pkg/mod/cache"], riskLevel: .low),
            DevTarget(name: "Go Build Cache", paths: ["Library/Caches/go-build"], riskLevel: .low),

            // Ruby
            DevTarget(name: "Gem Cache", paths: [".gem/ruby"], riskLevel: .low),
            DevTarget(name: "Bundler Cache", paths: [".bundle/cache"], riskLevel: .low),

            // Java
            DevTarget(name: "Gradle Cache", paths: [".gradle/caches"], riskLevel: .low),
            DevTarget(name: "Maven Repository", paths: [".m2/repository"], riskLevel: .medium),

            // Docker
            DevTarget(name: "Docker BuildX Cache", paths: ["Library/Containers/com.docker.docker/Data/docker/buildx"], riskLevel: .low),

            // IDE Caches
            DevTarget(name: "VS Code Cache", paths: ["Library/Caches/com.microsoft.VSCode"], riskLevel: .low),
            DevTarget(name: "Cursor Cache", paths: ["Library/Caches/com.todesktop.230313mzl4w4u92"], riskLevel: .low),
            DevTarget(name: "JetBrains Cache", paths: ["Library/Caches/JetBrains"], riskLevel: .low),
            DevTarget(name: "Zed Cache", paths: ["Library/Caches/dev.zed.Zed"], riskLevel: .low),

            // Cloud CLIs
            DevTarget(name: "AWS CLI Cache", paths: [".aws/cli/cache"], riskLevel: .low),
            DevTarget(name: "GCloud Cache", paths: [".config/gcloud/logs"], riskLevel: .low),
        ]
    }

    func scan() async -> [CleanableItem] {
        var items: [CleanableItem] = []

        for target in targets {
            for path in target.paths {
                let url = home.appendingPathComponent(path)
                guard fileManager.fileExists(atPath: url.path) else { continue }

                let size = fileManager.directorySize(at: url)
                guard size > 1_000_000 else { continue } // Skip < 1MB

                items.append(CleanableItem(
                    path: url,
                    displayName: target.name,
                    sizeBytes: size,
                    modificationDate: fileManager.modificationDate(at: url),
                    category: .developer,
                    riskLevel: target.riskLevel
                ))
            }
        }

        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
