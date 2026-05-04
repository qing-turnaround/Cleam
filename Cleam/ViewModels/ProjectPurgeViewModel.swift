import SwiftUI

@MainActor
class ProjectPurgeViewModel: ObservableObject {
    @Published var projects: [ProjectRoot] = []
    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var scanDirectories: [URL] = []
    @Published var result: OperationResult?

    private let fileOps: FileOperationService

    init(fileOps: FileOperationService) {
        self.fileOps = fileOps
        self.scanDirectories = [URL.home.appendingPathComponent("Developer")]
    }

    var totalPurgeSize: UInt64 {
        projects.flatMap(\.artifacts).filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedArtifactCount: Int {
        projects.flatMap(\.artifacts).filter(\.isSelected).count
    }

    func scan() async {
        isScanning = true
        projects = []

        for dir in scanDirectories {
            await scanDirectory(dir, maxDepth: 4, currentDepth: 0)
        }

        projects.sort { $0.totalArtifactSize > $1.totalArtifactSize }
        isScanning = false
        hasScanned = true
    }

    func purgeSelected() async {
        let startTime = Date()
        let urls = projects.flatMap(\.artifacts).filter(\.isSelected).map(\.path)
        guard !urls.isEmpty else { return }

        let result = await fileOps.deleteBatch(urls: urls, isDryRun: false) { _, _ in }

        self.result = OperationResult(
            success: result.errors.isEmpty,
            freedBytes: result.freedBytes,
            deletedCount: result.deletedCount,
            failedCount: result.errors.count,
            errors: result.errors,
            duration: Date().timeIntervalSince(startTime)
        )

        await scan()
    }

    func toggleArtifact(projectIndex: Int, artifactIndex: Int) {
        guard projects.indices.contains(projectIndex),
              projects[projectIndex].artifacts.indices.contains(artifactIndex) else { return }
        projects[projectIndex].artifacts[artifactIndex].isSelected.toggle()
    }

    private func scanDirectory(_ dir: URL, maxDepth: Int, currentDepth: Int) async {
        guard currentDepth < maxDepth else { return }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }

        for type in ProjectType.allCases where type != .mixed {
            for indicator in type.indicators where !indicator.contains("*") {
                if contents.contains(where: { $0.lastPathComponent == indicator }) {
                    var artifacts: [PurgeArtifact] = []
                    for artifactName in type.artifactDirectories where !artifactName.contains("*") {
                        let artifactURL = dir.appendingPathComponent(artifactName)
                        if fm.fileExists(atPath: artifactURL.path) {
                            let size = fm.directorySize(at: artifactURL)
                            if size > 1_000_000 {
                                artifacts.append(PurgeArtifact(
                                    path: artifactURL,
                                    name: artifactName,
                                    sizeBytes: size,
                                    lastModified: fm.modificationDate(at: artifactURL)
                                ))
                            }
                        }
                    }
                    if !artifacts.isEmpty {
                        let project = ProjectRoot(
                            path: dir,
                            name: dir.lastPathComponent,
                            projectType: type,
                            indicators: [indicator],
                            artifacts: artifacts
                        )
                        projects.append(project)
                    }
                    return
                }
            }
        }

        for url in contents where url.isDirectory {
            let name = url.lastPathComponent
            if ["node_modules", ".build", "target", ".git", "DerivedData", "vendor", ".venv", "venv"].contains(name) { continue }
            await scanDirectory(url, maxDepth: maxDepth, currentDepth: currentDepth + 1)
        }
    }
}
