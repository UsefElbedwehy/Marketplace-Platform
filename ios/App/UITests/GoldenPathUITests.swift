import XCTest

/// The golden path ⭐ (docs/planning/11-roadmap.md Phase 4 exit criterion):
/// create + browse + filter listings for three structurally different
/// verticals — Cars (option fields + a Brand→Model dependency), Phones (the
/// same dependency pattern, a different vertical), Apartments (almost
/// entirely number/bool fields, no options at all) — through the *exact
/// same* `CreateListingView`/`DynamicFormView` code, against the real local
/// backend gateway.
///
/// A freshly created listing lands in `draft` status (backend/src/listing_
/// service.ts's `ALLOWED_TRANSITIONS`) and RLS hides non-`published` rows
/// from everyone but the owner/a moderator — only a moderator can move a
/// listing to `published` (`MODERATOR_ONLY_TARGETS`), and there is no
/// self-serve publish button for the seller. So proving the Search tab's
/// browse+filter genuinely surfaces a new listing requires walking it
/// through draft → pending_review → published via the real moderation
/// queue, not just creating it.
final class GoldenPathUITests: XCTestCase {
    private let carTitle = "2019 BMW golden path"
    private let apartmentTitle = "2BR apartment golden path"
    private let phoneTitle = "iPhone 15 golden path"

    func testCreateModerateBrowseAndFilterAcrossThreeStructurallyDifferentVerticals() {
        let app = XCUIApplication()
        app.launch()
        signIn(as: "seller", app: app)

        createCarListing(app: app)
        performOwnerAction("Submit for review", forListingTitled: carTitle, app: app)

        signIn(as: "moderator", app: app)
        app.tabBars.firstMatch.buttons["Sell"].tap()
        performOwnerAction("Approve", forListingTitled: carTitle, app: app)

        signIn(as: "seller", app: app)
        createApartmentListing(app: app)
        createPhoneListing(app: app)

        // Browse + filter: Search tab, Cars category, filter brand=BMW —
        // should surface the now-published Car listing.
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Search"].tap()
        tap(identifier: "search.category.cars", in: app)

        let filtersButton = app.buttons["search.filters-button"]
        XCTAssertTrue(filtersButton.waitForExistence(timeout: 10))
        filtersButton.tap()
        selectDropdownOption(fieldKey: "brand", optionLabel: "BMW", app: app)
        app.navigationBars.buttons["Apply"].tap()

        let bmwResult = app.staticTexts[carTitle]
        XCTAssertTrue(bmwResult.waitForExistence(timeout: 15), "Filtering Search by brand=BMW should surface the published Car listing")
    }

    // MARK: - Per-vertical creation

    private func createCarListing(app: XCUIApplication) {
        openCreateListingForm(app: app)
        selectCategory(path: ["category.vehicles", "category.cars"], app: app)

        fillText(identifier: "create-listing.title", text: carTitle, app: app)
        fillText(identifier: "create-listing.price", text: "85000", app: app)

        selectDropdownOption(fieldKey: "brand", optionLabel: "BMW", app: app)
        selectDropdownOption(fieldKey: "model", optionLabel: "X5", app: app)
        fillText(identifier: "dynamic-field.year", text: "2019", app: app)
        fillText(identifier: "dynamic-field.mileage", text: "42000", app: app)
        selectDropdownOption(fieldKey: "transmission", optionLabel: "Automatic", app: app)
        selectDropdownOption(fieldKey: "fuelType", optionLabel: "Petrol", app: app)
        selectDropdownOption(fieldKey: "condition", optionLabel: "Used", app: app)

        submitAndExpectReturnToMyListings(app: app, expectedTitle: carTitle)
    }

    private func createApartmentListing(app: XCUIApplication) {
        openCreateListingForm(app: app)
        selectCategory(path: ["category.real-estate", "category.apartments"], app: app)

        fillText(identifier: "create-listing.title", text: apartmentTitle, app: app)
        fillText(identifier: "create-listing.price", text: "3500", app: app)

        fillText(identifier: "dynamic-field.bedrooms", text: "2", app: app)
        fillText(identifier: "dynamic-field.bathrooms", text: "2", app: app)
        fillText(identifier: "dynamic-field.area", text: "120", app: app)

        submitAndExpectReturnToMyListings(app: app, expectedTitle: apartmentTitle)
    }

    private func createPhoneListing(app: XCUIApplication) {
        openCreateListingForm(app: app)
        selectCategory(path: ["category.electronics", "category.phones"], app: app)

        fillText(identifier: "create-listing.title", text: phoneTitle, app: app)
        fillText(identifier: "create-listing.price", text: "3200", app: app)

        selectDropdownOption(fieldKey: "brand", optionLabel: "Apple", app: app)
        selectDropdownOption(fieldKey: "model", optionLabel: "iPhone 15", app: app)
        selectDropdownOption(fieldKey: "storage", optionLabel: "128GB", app: app)
        selectDropdownOption(fieldKey: "condition", optionLabel: "New", app: app)

        submitAndExpectReturnToMyListings(app: app, expectedTitle: phoneTitle)
    }

    // MARK: - Shared steps

    private func openCreateListingForm(app: XCUIApplication) {
        app.tabBars.firstMatch.buttons["Sell"].tap()
        let newListingButton = app.buttons["sell.new-listing"]
        XCTAssertTrue(newListingButton.waitForExistence(timeout: 10))
        newListingButton.tap()
    }

    private func selectCategory(path: [String], app: XCUIApplication) {
        let picker = app.buttons["create-listing.category-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        for (index, identifier) in path.enumerated() {
            let node = elementByIdentifier(identifier, in: app)
            XCTAssertTrue(node.waitForExistence(timeout: 10), "Expected category node \(identifier) at drill-down step \(index)")
            node.tap()
        }
    }

    private func selectDropdownOption(fieldKey: String, optionLabel: String, app: XCUIApplication) {
        let menu = elementByIdentifier("dynamic-field.\(fieldKey)", in: app)
        XCTAssertTrue(menu.waitForExistence(timeout: 10), "Expected dropdown for \(fieldKey)")
        menu.tap()
        let option = app.buttons[optionLabel]
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Expected option '\(optionLabel)' for \(fieldKey)")
        option.tap()
    }

    private func fillText(identifier: String, text: String, app: XCUIApplication) {
        let field = elementByIdentifier(identifier, in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Expected text field \(identifier)")
        field.tap()
        field.typeText(text)
        // No explicit keyboard dismissal: the decimal-pad keyboard used by
        // number fields has no Return key, and tapping the next field
        // naturally moves first responder without needing one.
    }

    private func submitAndExpectReturnToMyListings(app: XCUIApplication, expectedTitle: String) {
        let submit = app.buttons["create-listing.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 10))
        submit.tap()

        var resultRow = app.staticTexts[expectedTitle]
        if !resultRow.waitForExistence(timeout: 8) {
            // MyListingsView's `.task` only loads once per mount; popping
            // back from create-listing doesn't necessarily retrigger it, so
            // fall back to a pull-to-refresh before treating this as a
            // failure.
            app.scrollViews.firstMatch.swipeDown()
            resultRow = app.staticTexts[expectedTitle]
        }
        XCTAssertTrue(resultRow.waitForExistence(timeout: 15), "Expected '\(expectedTitle)' to appear in My listings after a successful create")
    }

    /// Taps an owner/moderator action button (e.g. "Submit for review",
    /// "Approve") scoped to the specific listing row containing `title` —
    /// both "My listings" and the moderation queue share the same
    /// `my-listing-row.<id>` container identifier, so a plain
    /// `app.buttons[action]` lookup would be ambiguous whenever more than
    /// one row is showing.
    private func performOwnerAction(_ action: String, forListingTitled title: String, app: XCUIApplication) {
        let row = rowElement(containingText: title, app: app)
        let actionButton = row.buttons[action]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 10), "Expected '\(action)' action on the row for '\(title)'")
        actionButton.tap()
    }

    private func rowElement(containingText title: String, app: XCUIApplication) -> XCUIElement {
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'my-listing-row.'"))
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            let count = rows.count
            for i in 0..<count {
                let row = rows.element(boundBy: i)
                if row.staticTexts[title].exists {
                    return row
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("No listing row found containing '\(title)'")
        return app
    }

    private func tap(identifier: String, in app: XCUIApplication) {
        let element = elementByIdentifier(identifier, in: app)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        element.tap()
    }

    private func elementByIdentifier(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// Signs in as the requested dev role, first signing out if a different
    /// (or the Keychain-persisted) session is already active.
    private func signIn(as role: String, app: XCUIApplication) {
        let identityMap: [String: String] = [
            "buyer": "dev-identity.buyer", "seller": "dev-identity.seller", "moderator": "dev-identity.moderator",
            "admin": "dev-identity.admin", "catalog_editor": "dev-identity.catalog_editor",
        ]
        guard let identityId = identityMap[role] else { fatalError("unknown role \(role)") }

        let identityCard = app.staticTexts[identityId]
        let tabBar = app.tabBars.firstMatch
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline, !identityCard.exists, !tabBar.exists {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        if tabBar.exists {
            tabBar.buttons["Profile"].tap()
            let profileTag = app.staticTexts["profile.appRole"]
            XCTAssertTrue(profileTag.waitForExistence(timeout: 10))
            if profileTag.label == "app_role: \(role)" {
                tabBar.buttons["Home"].tap()
                return // already signed in as the requested role
            }
            let signOut = app.buttons["Sign out"]
            XCTAssertTrue(signOut.waitForExistence(timeout: 10))
            signOut.tap()
        }

        XCTAssertTrue(identityCard.waitForExistence(timeout: 10))
        identityCard.tap()
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
    }
}
