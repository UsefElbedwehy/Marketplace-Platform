// swift-tools-version: 5.9
import PackageDescription

// Development Schema (config + theme) DTOs, a bundled default config, and the
// SwiftData cache behind them (ADR-0013). Depends on Core + Networking only —
// never DomainKit, so it knows nothing about `AppConfiguration`/`ThemeTokens`
// entities; `DataKit` maps this package's DTOs onto those.
let package = Package(
    name: "Configuration",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Configuration", targets: ["Configuration"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Networking"),
    ],
    targets: [
        .target(name: "Configuration", dependencies: ["Core", "Networking"], resources: [.process("Resources")]),
        .testTarget(name: "ConfigurationTests", dependencies: ["Configuration"]),
    ]
)
