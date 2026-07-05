// swift-tools-version: 5.9
import PackageDescription

// Pure domain (docs/planning/02-ios-architecture.md §1): entities, repository
// protocols, use cases. Depends on Core only (per 01-system-architecture.md §4's
// allowed-dependency table) — never Networking, DataKit, or DesignSystem.
let package = Package(
    name: "DomainKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "DomainKit", targets: ["DomainKit"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(name: "DomainKit", dependencies: ["Core"]),
        .testTarget(name: "DomainKitTests", dependencies: ["DomainKit"]),
    ]
)
