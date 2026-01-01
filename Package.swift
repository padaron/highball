// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Highball",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
    ],
    targets: [
        .executableTarget(
            name: "Highball",
            dependencies: ["KeychainAccess"],
            path: "Sources/Highball"
        )
    ]
)
