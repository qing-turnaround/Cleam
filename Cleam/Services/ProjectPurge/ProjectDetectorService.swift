import Foundation

actor ProjectDetectorService {
    private let fileManager = FileManager.default

    struct ProjectIndicator {
        let fileName: String
        let projectType: ProjectType
    }

    private let indicators: [ProjectIndicator] = [
        ProjectIndicator(fileName: "package.json", projectType: .node),
        ProjectIndicator(fileName: "Package.swift", projectType: .swift),
        ProjectIndicator(fileName: "Cargo.toml", projectType: .rust),
        ProjectIndicator(fileName: "go.mod", projectType: .go),
        ProjectIndicator(fileName: "pyproject.toml", projectType: .python),
        ProjectIndicator(fileName: "setup.py", projectType: .python),
        ProjectIndicator(fileName: "requirements.txt", projectType: .python),
        ProjectIndicator(fileName: "Gemfile", projectType: .ruby),
        ProjectIndicator(fileName: "pom.xml", projectType: .java),
        ProjectIndicator(fileName: "build.gradle", projectType: .java),
        ProjectIndicator(fileName: "build.gradle.kts", projectType: .java),
        ProjectIndicator(fileName: "pubspec.yaml", projectType: .flutter),
        ProjectIndicator(fileName: "composer.json", projectType: .php),
    ]

    private let skipDirectories: Set<String> = [
        "node_modules", ".build", "target", ".git", "DerivedData",
        "vendor", ".venv", "venv", "dist", "__pycache__",
        ".next", ".nuxt", "build", ".gradle", "Pods",
    ]

    func detect(in directories: [URL], maxDepth: Int = 5) async -> [ProjectRoot] {
        var projects: [ProjectRoot] = []

        for dir in directories {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            await scanDirectory(dir, maxDepth: maxDepth, currentDepth: 0, projects: &projects)
        }

        return projects.sorted { $0.totalArtifactSize > $1.totalArtifactSize }
    }

    private func scanDirectory(_ dir: URL, maxDepth: Int, currentDepth: Int, projects: inout [ProjectRoot]) async {
        guard currentDepth < maxDepth else { return }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let fileNames = Set(contents.map(\.lastPathComponent))

        // Check for project indicators
        var detectedType: ProjectType?
        var detectedIndicators: [String] = []

        for indicator in indicators {
            if fileNames.contains(indicator.fileName) {
                detectedType = indicator.projectType
                detectedIndicators.append(indicator.fileName)
                break
            }
        }

        // Also check for Xcode projects
        if contents.contains(where: { $0.pathExtension == "xcodeproj" || $0.pathExtension == "xcworkspace" }) {
            detectedType = .swift
            detectedIndicators.append("*.xcodeproj")
        }

        // Check for .csproj / .sln
        if contents.contains(where: { $0.pathExtension == "csproj" || $0.pathExtension == "sln" }) {
            detectedType = .dotnet
            detectedIndicators.append("*.csproj")
        }

        if let type = detectedType {
            var artifacts: [PurgeArtifact] = []

            for artifactName in type.artifactDirectories where !artifactName.contains("*") {
                let artifactURL = dir.appendingPathComponent(artifactName)
                guard fileManager.fileExists(atPath: artifactURL.path) else { continue }

                let size = fileManager.directorySize(at: artifactURL)
                guard size > 1_000_000 else { continue } // > 1MB

                artifacts.append(PurgeArtifact(
                    path: artifactURL,
                    name: artifactName,
                    sizeBytes: size,
                    lastModified: fileManager.modificationDate(at: artifactURL)
                ))
            }

            if !artifacts.isEmpty {
                projects.append(ProjectRoot(
                    path: dir,
                    name: dir.lastPathComponent,
                    projectType: type,
                    indicators: detectedIndicators,
                    artifacts: artifacts
                ))
            }
            return // Don't recurse into detected projects
        }

        // Recurse into subdirectories
        for url in contents where url.isDirectory {
            let name = url.lastPathComponent
            guard !skipDirectories.contains(name) else { continue }
            guard !name.hasPrefix(".") else { continue }
            await scanDirectory(url, maxDepth: maxDepth, currentDepth: currentDepth + 1, projects: &projects)
        }
    }
}
