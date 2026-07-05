// swift-tools-version: 5.9
import PackageDescription

// The iOS realization of the Dynamic Category & Attribute Engine ⭐
// (docs/planning/05-dynamic-schema-engine.md §6): turns a `ComposedSchema`
// into a rendered, validated SwiftUI form. May depend on DomainKit +
// DesignSystem only — never Networking or DataKit (01-system-architecture.md
// §4), so it has no idea how a schema was fetched, only how to render one.
let package = Package(
    name: "DynamicForms",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DynamicForms", targets: ["DynamicForms"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../Configuration"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
    ],
    targets: [
        .target(name: "DynamicForms", dependencies: ["Core", "DomainKit", "DesignSystem"]),
        .testTarget(
            name: "DynamicFormsTests",
            dependencies: [
                "DynamicForms",
                "Core",
                "DomainKit",
                "DesignSystem",
                "Configuration", // test-only, for BundledDefaults.theme() — same as DesignSystemTests
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
