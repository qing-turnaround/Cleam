import Foundation

actor ArtifactScannerService {
    private let fileManager = FileManager.default

    struct ArtifactPattern {
        let name: String
        let projectTypes: [ProjectType]
        let minSizeBytes: UInt64
    }

    private let patterns: [ArtifactPattern] = [
        ArtifactPattern(name: "node_modules", projectTypes: [.node], minSizeBytes: 10_000_000),
        ArtifactPattern(name: ".next", projectTypes: [.node], minSizeBytes: 1_000_000),
        ArtifactPattern(name: ".nuxt", projectTypes: [.node], minSizeBytes: 1_000_000),
        ArtifactPattern(name: "dist", projectTypes: [.node], minSizeBytes: 1_000_000),
        ArtifactPattern(name: ".output", projectTypes: [.node], minSizeBytes: 1_000_000),
        ArtifactPattern(name: ".build", projectTypes: [.swift], minSizeBytes: 5_000_000),
        ArtifactPattern(name: "DerivedData", projectTypes: [.swift], minSizeBytes: 10_000_000),
        ArtifactPattern(name: "target", projectTypes: [.rust, .java], minSizeBytes: 10_000_000),
        ArtifactPattern(name: "build", projectTypes: [.java, .flutter], minSizeBytes: 5_000_000),
        ArtifactPattern(name: ".gradle", projectTypes: [.java], minSizeBytes: 5_000_000),
        ArtifactPattern(name: "__pycache__", projectTypes: [.python], minSizeBytes: 100_000),
        ArtifactPattern(name: ".venv", projectTypes: [.python], minSizeBytes: 10_000_000),
        ArtifactPattern(name: "venv", projectTypes: [.python], minSizeBytes: 10_000_000),
        ArtifactPattern(name: ".tox", projectTypes: [.python], minSizeBytes: 5_000_000),
        ArtifactPattern(name: ".dart_tool", projectTypes: [.flutter], minSizeBytes: 1_000_000),
        ArtifactPattern(name: "Pods", projectTypes: [.swift], minSizeBytes: 10_000_000),
        ArtifactPattern(name: "vendor/bundle", projectTypes: [.ruby], minSizeBytes: 5_000_000),
        ArtifactPattern(name: "bin", projectTypes: [.dotnet], minSizeBytes: 1_000_000),
        ArtifactPattern(name: "obj", projectTypes: [.dotnet], minSizeBytes: 1_000_000),
    ]

    func scanArtifacts(in projectDir: URL, projectType: ProjectType) -> [PurgeArtifact] {
        var artifacts: [PurgeArtifact] = []

        let relevantPatterns = patterns.filter { pattern in
            pattern.projectTypes.contains(projectType)
        }

        for pattern in relevantPatterns {
            let artifactURL = projectDir.appendingPathComponent(pattern.name)
            guard fileManager.fileExists(atPath: artifactURL.path) else { continue }

            let size = fileManager.directorySize(at: artifactURL)
            guard size >= pattern.minSizeBytes else { continue }

            artifacts.append(PurgeArtifact(
                path: artifactURL,
                name: pattern.name,
                sizeBytes: size,
                lastModified: fileManager.modificationDate(at: artifactURL)
            ))
        }

        return artifacts.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    func estimateTotalSize(artifacts: [PurgeArtifact]) -> UInt64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }
}
