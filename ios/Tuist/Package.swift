// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    // DesignSystem's test target depends on swift-snapshot-testing (test-only —
    // the App target itself never imports it); Tuist still walks the whole
    // package graph and needs a product type for everything it finds.
    productTypes: [
        "SnapshotTesting": .framework
    ]
)
#endif

let package = Package(
    name: "MarketplacePlatformDependencies",
    dependencies: [
        .package(path: "../Packages/Core"),
        .package(path: "../Packages/DomainKit"),
        .package(path: "../Packages/Networking"),
        .package(path: "../Packages/Configuration"),
        .package(path: "../Packages/DesignSystem"),
        .package(path: "../Packages/DataKit"),
        .package(path: "../Packages/DynamicForms"),
        .package(path: "../Packages/Features/Listings"),
        .package(path: "../Packages/Features/Search"),
        .package(path: "../Packages/Features/Chat"),
        // DesignSystem's test target's dependency — not used by the App
        // target, but Tuist walks the whole package graph and needs every
        // product it finds (even test-only ones) declared as a top-level
        // dependency here to know how to package it.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
    ]
)
