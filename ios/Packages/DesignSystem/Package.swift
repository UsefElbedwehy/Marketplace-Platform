// swift-tools-version: 5.9
import PackageDescription

// The theme engine + component library (ADR-0005). May depend on Core and
// Configuration (for theme *tokens* only) — never Networking, DomainKit, or
// Features (01-system-architecture.md §4). No raw color/font literal may
// appear outside this package (ios/Tooling/lint-no-raw-colors.sh).
let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Configuration"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
    ],
    targets: [
        .target(name: "DesignSystem", dependencies: ["Core", "Configuration"]),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem",
                "Configuration",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
