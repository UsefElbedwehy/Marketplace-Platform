// swift-tools-version: 5.9
import PackageDescription

// The ONLY module permitted to know how requests actually travel (currently
// URLSession → Edge Functions; no Supabase SDK is used at all yet, so the
// "no Supabase import outside Networking" boundary is trivially satisfied —
// see docs/planning/08-api-auth.md §4 and 01-system-architecture.md §4.
let package = Package(
    name: "Networking",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(name: "Networking", dependencies: ["Core"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
    ]
)
