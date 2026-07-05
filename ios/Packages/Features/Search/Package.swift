// swift-tools-version: 5.9
import PackageDescription

// One Feature = one SPM target (ADR-0015). May depend on DomainKit +
// DesignSystem + DynamicForms only — never Listings or any other Features/*
// module (01-system-architecture.md §4). This does mean a couple of small
// presentational views (a category list row, a listing result row) are
// duplicated between Search and Listings rather than shared — the
// architecture's own tradeoff for guaranteeing Features stay independent;
// see each package's `README.md`.
let package = Package(
    name: "Search",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Search", targets: ["Search"])
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DomainKit"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../DynamicForms"),
    ],
    targets: [
        .target(name: "Search", dependencies: ["Core", "DomainKit", "DesignSystem", "DynamicForms"]),
        .testTarget(name: "SearchTests", dependencies: ["Search", "Core", "DomainKit", "DynamicForms"]),
    ]
)
