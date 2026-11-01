// swift-tools-version: 6.0
import PackageDescription

// Core is pure Swift (CLAUDE.md rule 1). The same sources are compiled by the
// Xcode app target (synchronized folder) and by SwiftPM for fast `swift test`.
let package = Package(
    name: "BlockFitCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "BlockFitCore", targets: ["BlockFitCore"])],
    targets: [
        .target(name: "BlockFitCore", path: "ios-template/Core"),
        .testTarget(name: "BlockFitCoreTests", dependencies: ["BlockFitCore"], path: "Tests/BlockFitCoreTests"),
    ]
)
