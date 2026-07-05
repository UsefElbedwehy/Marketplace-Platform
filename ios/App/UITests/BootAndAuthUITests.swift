import XCTest

/// Drives the real app against the real local backend gateway
/// (`backend/scripts/serve-local.ts` on :8000) — no mocks. Requires the
/// gateway running locally; see `ios/App/README.md`.
final class BootAndAuthUITests: XCTestCase {
    func testBootThenDevSignInReachesTheThemedTabShell() {
        let app = XCUIApplication()
        app.launch()

        let devAdminCard = app.staticTexts["dev-identity.admin"]
        XCTAssertTrue(devAdminCard.waitForExistence(timeout: 15), "Boot should finish and the auth screen should list Dev Admin")

        save(app.screenshot(), as: "auth-screen")

        devAdminCard.tap()

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 10), "Sign-in should succeed and land on the tab shell")
        save(app.screenshot(), as: "home-tab-signed-in")

        profileTab.tap()

        let appRoleLabel = app.staticTexts["profile.appRole"]
        XCTAssertTrue(appRoleLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(appRoleLabel.label, "app_role: admin")
        save(app.screenshot(), as: "profile-tab-signed-in")

        let signOutButton = app.buttons["Sign out"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()

        let devAdminCardAgain = app.staticTexts["dev-identity.admin"]
        XCTAssertTrue(devAdminCardAgain.waitForExistence(timeout: 10), "Sign-out should return to the auth screen")
    }

    /// Saved to a fixed path (not an XCTAttachment) so they can be inspected
    /// directly from outside the test run — Phase 3 verification needs actual
    /// visual proof, not just a passing assertion.
    private func save(_ screenshot: XCUIScreenshot, as name: String) {
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/ios-verification-\(name).png"))
    }
}
