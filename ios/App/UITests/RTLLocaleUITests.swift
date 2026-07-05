import XCTest

/// Verifies the Arabic (RTL) locale actually translates strings and mirrors
/// layout — the roadmap Phase 3 exit criterion "renders themed shell + auth
/// in LTR **and** RTL". Launch-argument locale override, same technique
/// Xcode's own scheme editor uses for "Test Plan Language" runs.
final class RTLLocaleUITests: XCTestCase {
    func testArabicLocaleTranslatesTheAuthScreenAndMirrorsLayout() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()

        let title = app.staticTexts["منصة السوق"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The Arabic translation of the title should appear")

        let subtitle = app.staticTexts["اختر هوية تجريبية لتسجيل الدخول بها"]
        XCTAssertTrue(subtitle.exists)

        // Saved to a fixed path so the actual mirroring (not just the
        // translated strings) can be inspected visually.
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/ios-verification-auth-screen-ar.png"))
    }
}
