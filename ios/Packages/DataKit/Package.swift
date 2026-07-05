// swift-tools-version: 5.9
import PackageDescription

// Repository implementations, DTO->Entity mapping (docs/planning/
// 02-ios-architecture.md §1). Depends on DomainKit + Networking + Configuration
// — never DesignSystem or Features (01-system-architecture.md §4).
let package = Package(
    name: "DataKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DataKit", targets: ["DataKit"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DomainKit"),
        .package(path: "../Networking"),
        .package(path: "../Configuration"),
    ],
    targets: [
        .target(name: "DataKit", dependencies: ["Core", "DomainKit", "Networking", "Configuration"]),
        .testTarget(name: "DataKitTests", dependencies: ["DataKit", "Core", "Networking", "DomainKit"]),
    ]
)
