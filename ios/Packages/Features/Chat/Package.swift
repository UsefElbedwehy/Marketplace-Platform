// swift-tools-version: 5.9
import PackageDescription

// Buyer↔seller chat ⭐ (Phase 6). One Feature = one SPM target (ADR-0015).
// May depend on DomainKit + DesignSystem only — never Listings/Search or any
// other Features/* module (01-system-architecture.md §4). Poll-based, not
// Realtime — see docs/planning/03-backend-architecture.md §6 and
// DomainKit's `ChatRepository` doc comment for why.
let package = Package(
    name: "Chat",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Chat", targets: ["Chat"])
    ],
    dependencies: [
        .package(path: "../../Core"),
        .package(path: "../../DomainKit"),
        .package(path: "../../DesignSystem"),
    ],
    targets: [
        .target(name: "Chat", dependencies: ["Core", "DomainKit", "DesignSystem"]),
        .testTarget(name: "ChatTests", dependencies: ["Chat", "Core", "DomainKit"]),
    ]
)
