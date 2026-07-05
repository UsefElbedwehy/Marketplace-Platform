import XCTest

/// A lighter smoke pass than `BootAndAuthUITests` — proves Home/Search/Sell
/// now render real `Listings`/`Search` content (not the Phase 3 placeholders)
/// after wiring the Feature packages into `TabCoordinator`. The golden-path
/// create/browse/filter flow itself is exercised end-to-end elsewhere.
final class TabShellSmokeUITests: XCTestCase {
    func testHomeSearchAndSellTabsRenderRealContentAfterSignIn() {
        let app = XCUIApplication()
        app.launch()

        // The Keychain-persisted session (TokenStore) survives across
        // `app.launch()` within the same Simulator, so a prior test's
        // sign-in can leave this launch already past the auth screen — sign
        // in only if that screen is actually what's showing (poll for
        // whichever of the two shows up first).
        let devAdminCard = app.staticTexts["dev-identity.admin"]
        let tabBar = app.tabBars.firstMatch
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline, !devAdminCard.exists, !tabBar.exists {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        if devAdminCard.exists {
            devAdminCard.tap()
        }

        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))

        // Home: the feed should load with no listings yet (or some), not a
        // crash and not the old "The feed lands in Phase 6" placeholder text.
        save(app.screenshot(), as: "home-tab-wired")
        XCTAssertFalse(app.staticTexts["The feed lands in Phase 6 — this proves the themed tab shell today."].exists)

        tabBar.buttons["Search"].tap()
        // Query by accessibility identifier, not label text — SwiftUI List
        // rows can surface as either `.staticTexts` or `.cells`/`.buttons`
        // depending on OS/runtime accessibility-engine version, and the
        // identifier is stable across both.
        let carsCategory = app.descendants(matching: .any)["search.category.cars"]
        XCTAssertTrue(carsCategory.waitForExistence(timeout: 20), "Search should list real leaf categories fetched from the backend")
        save(app.screenshot(), as: "search-tab-wired")

        tabBar.buttons["Sell"].tap()
        let newListingButton = app.buttons["sell.new-listing"]
        XCTAssertTrue(newListingButton.waitForExistence(timeout: 10))
        save(app.screenshot(), as: "sell-tab-wired")

        // Sign out so this test doesn't leave a Keychain-persisted session
        // behind for whichever test runs next (matches GoldenPathUITests /
        // SchemaLiveEditUITests, which both do the same).
        tabBar.buttons["Profile"].tap()
        let signOut = app.buttons["Sign out"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 10))
        signOut.tap()
        XCTAssertTrue(devAdminCard.waitForExistence(timeout: 10))
    }

    private func save(_ screenshot: XCUIScreenshot, as name: String) {
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/ios-verification-\(name).png"))
    }
}
