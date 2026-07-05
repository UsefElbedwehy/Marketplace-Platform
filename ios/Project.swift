import ProjectDescription

let project = Project(
    name: "MarketplacePlatform",
    targets: [
        .target(
            name: "MarketplacePlatform",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.marketplace-platform.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
            ]),
            sources: ["App/Sources/App/**"],
            resources: ["App/Resources/**"],
            dependencies: [
                .external(name: "Core"),
                .external(name: "DomainKit"),
                .external(name: "Networking"),
                .external(name: "Configuration"),
                .external(name: "DesignSystem"),
                .external(name: "DataKit"),
                .external(name: "DynamicForms"),
                .external(name: "Listings"),
                .external(name: "Search"),
                .external(name: "Chat"),
            ]
        ),
        // Drives the real Simulator app end-to-end (boot -> auth -> tab
        // shell) against the real local backend gateway — the CLI has no
        // pointer/touch input for xcrun simctl, so this is how Phase 3's
        // exit criteria ("boots, fetches config+theme, renders themed shell
        // + auth... DI graph resolves") gets verified beyond a screenshot.
        .target(
            name: "MarketplacePlatformUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.marketplace-platform.app.uitests",
            deploymentTargets: .iOS("17.0"),
            sources: ["App/UITests/**"],
            dependencies: [.target(name: "MarketplacePlatform")]
        ),
    ]
)
