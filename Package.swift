// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cleam",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Cleam",
            path: "Cleam"
        ),
        .testTarget(
            name: "CleamTests",
            dependencies: ["Cleam"],
            path: "CleamTests"
        ),
    ]
)
