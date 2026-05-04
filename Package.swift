// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cleam",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Cleam",
            path: "Cleam",
            exclude: ["Resources/Cleam.entitlements", "Resources/Info.plist"]
        ),
        .testTarget(
            name: "CleamTests",
            dependencies: ["Cleam"],
            path: "CleamTests"
        ),
    ]
)
