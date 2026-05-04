import Foundation

enum ProjectType: String, CaseIterable {
    case node = "Node.js"
    case swift = "Swift"
    case rust = "Rust"
    case go = "Go"
    case python = "Python"
    case ruby = "Ruby"
    case java = "Java"
    case dotnet = ".NET"
    case flutter = "Flutter"
    case php = "PHP"
    case mixed = "Mixed"

    var icon: String {
        switch self {
        case .node: return "n.circle.fill"
        case .swift: return "swift"
        case .rust: return "gear.circle.fill"
        case .go: return "g.circle.fill"
        case .python: return "p.circle.fill"
        case .ruby: return "r.circle.fill"
        case .java: return "j.circle.fill"
        case .dotnet: return "d.circle.fill"
        case .flutter: return "f.circle.fill"
        case .php: return "p.circle.fill"
        case .mixed: return "questionmark.circle.fill"
        }
    }

    var indicators: [String] {
        switch self {
        case .node: return ["package.json"]
        case .swift: return ["Package.swift", "*.xcodeproj", "*.xcworkspace"]
        case .rust: return ["Cargo.toml"]
        case .go: return ["go.mod"]
        case .python: return ["setup.py", "pyproject.toml", "requirements.txt"]
        case .ruby: return ["Gemfile"]
        case .java: return ["pom.xml", "build.gradle", "build.gradle.kts"]
        case .dotnet: return ["*.csproj", "*.sln"]
        case .flutter: return ["pubspec.yaml"]
        case .php: return ["composer.json"]
        case .mixed: return []
        }
    }

    var artifactDirectories: [String] {
        switch self {
        case .node: return ["node_modules", ".next", "dist", ".nuxt", ".output"]
        case .swift: return [".build", "DerivedData", "Build"]
        case .rust: return ["target"]
        case .go: return ["vendor"]
        case .python: return ["__pycache__", ".venv", "venv", ".tox", "dist", "*.egg-info"]
        case .ruby: return ["vendor/bundle", "tmp"]
        case .java: return ["target", "build", ".gradle"]
        case .dotnet: return ["bin", "obj", "packages"]
        case .flutter: return [".dart_tool", "build", ".flutter-plugins"]
        case .php: return ["vendor"]
        case .mixed: return []
        }
    }
}

struct ProjectRoot: Identifiable {
    let id: UUID
    let path: URL
    let name: String
    let projectType: ProjectType
    let indicators: [String]
    var artifacts: [PurgeArtifact]

    var totalArtifactSize: UInt64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }

    init(path: URL, name: String, projectType: ProjectType, indicators: [String], artifacts: [PurgeArtifact] = []) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.projectType = projectType
        self.indicators = indicators
        self.artifacts = artifacts
    }
}

struct PurgeArtifact: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let name: String
    let sizeBytes: UInt64
    let lastModified: Date?
    var isSelected: Bool

    init(path: URL, name: String, sizeBytes: UInt64, lastModified: Date? = nil, isSelected: Bool = true) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.sizeBytes = sizeBytes
        self.lastModified = lastModified
        self.isSelected = isSelected
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PurgeArtifact, rhs: PurgeArtifact) -> Bool {
        lhs.id == rhs.id
    }
}
