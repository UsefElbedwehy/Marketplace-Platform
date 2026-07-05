// swift-tools-version: 5.9
import PackageDescription

// Foundation package (docs/planning/02-ios-architecture.md §4, ADR-0015): the
// only iOS module allowed a third-party dependency (Factory, for DI —
// ADR-0012). Every other in-repo module reaches Factory only by importing
// Core, never Factory directly, so a future DI swap touches one place.
let package = Package(
    name: "Core",
    // .macOS is declared purely so `swift test` can run natively on the CI/dev
    // Mac without a simulator; the App target (ios/App) only ever targets iOS.
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", .upToNextMajor(from: "2.3.0"))
    ],
    targets: [
        .target(name: "Core", dependencies: [.product(name: "Factory", package: "Factory")]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
