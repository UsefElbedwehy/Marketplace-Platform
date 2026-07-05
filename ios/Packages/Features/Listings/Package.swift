// swift-tools-version: 5.9
import PackageDescription

// One Feature = one SPM target (ADR-0015). May depend on DomainKit +
// DesignSystem + DynamicForms only — never another Features/* module, never
// Networking/DataKit directly (01-system-architecture.md §4).
let package = Package(
    name: "Listings",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Listings", targets: ["Listings"])
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DomainKit"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../DynamicForms"),
    ],
    targets: [
        .target(name: "Listings", dependencies: ["Core", "DomainKit", "DesignSystem", "DynamicForms"]),
        .testTarget(name: "ListingsTests", dependencies: ["Listings", "Core", "DomainKit", "DynamicForms"]),
    ]
)
