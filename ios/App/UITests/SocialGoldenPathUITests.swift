import XCTest

/// The Phase 6 golden path ⭐ (docs/planning/11-roadmap.md Phase 6 exit
/// criteria): "buyer↔seller chat on a listing, favorite/unfavorite, receive
/// a push, view a seller profile — all flag-gated per client." Driven
/// against the real local backend gateway (no mocks), reusing the seller
/// →moderator publish flow already proven by `GoldenPathUITests`.
///
/// "Receive a push" is verified via the in-app notification list: the push
/// adapter is a logging no-op in this environment (see `PushPort`'s doc
/// comment) — there is no real APNs delivery to observe, so a delivered
/// `platform.outbox` row surfacing in Profile → Notifications is the
/// available proxy for it.
final class SocialGoldenPathUITests: XCTestCase {
    private let listingTitle = "Social phase6 fixture apartment"
    private let buyerMessage = "Hi, is this still available?"
    private let sellerReply = "Yes, it is!"

    func testFavoriteChatSellerProfileReviewAndNotificationRoundTrip() {
        let app = XCUIApplication()
        app.launch()

        publishFixtureListing(app: app)
        signIn(as: "buyer", app: app)

        app.tabBars.firstMatch.buttons["Home"].tap()
        openListingFromHome(app: app)

        favoriteThenConfirmInSavedListings(app: app)
        unfavoriteFromSavedListings(app: app)

        app.tabBars.firstMatch.buttons["Home"].tap()
        openListingFromHome(app: app)

        messageSeller(app: app)
        goBackToListingDetail(app: app)
        viewSellerProfileAndLeaveReview(app: app)

        signIn(as: "seller", app: app)
        replyAsSellerInChat(app: app)

        confirmNotificationReceived(app: app)
    }

    // MARK: - Steps

    /// Seller creates + submits an apartment listing, moderator approves it
    /// — the same publish path `GoldenPathUITests` exercises, using the
    /// simpler Apartments vertical (no dropdown option fields needed here).
    private func publishFixtureListing(app: XCUIApplication) {
        signIn(as: "seller", app: app)
        openCreateListingForm(app: app)
        selectCategory(path: ["category.real-estate", "category.apartments"], app: app)

        fillText(identifier: "create-listing.title", text: listingTitle, app: app)
        fillText(identifier: "create-listing.price", text: "3500", app: app)
        fillText(identifier: "dynamic-field.bedrooms", text: "2", app: app)
        fillText(identifier: "dynamic-field.bathrooms", text: "2", app: app)
        fillText(identifier: "dynamic-field.area", text: "120", app: app)

        submitAndExpectReturnToMyListings(app: app)
        performOwnerAction("Submit for review", app: app)

        signIn(as: "moderator", app: app)
        app.tabBars.firstMatch.buttons["Sell"].tap()
        performOwnerAction("Approve", app: app)
    }

    private func openListingFromHome(app: XCUIApplication) {
        // Scoped by the row's own (unique-per-listing-id) identifier rather
        // than a plain title lookup: reruns of this test accumulate more
        // than one published listing sharing `listingTitle`, which makes an
        // unscoped `app.staticTexts[listingTitle]` an ambiguous tap target.
        let row = rowElement(identifierPrefix: "listing-row.", containingText: listingTitle, app: app)
        row.tap()

        XCTAssertTrue(app.buttons["listing-detail.favorite-toggle"].waitForExistence(timeout: 10), "Expected to land on the listing detail screen")
    }

    private func favoriteThenConfirmInSavedListings(app: XCUIApplication) {
        let favoriteToggle = app.buttons["listing-detail.favorite-toggle"]
        XCTAssertTrue(favoriteToggle.waitForExistence(timeout: 10))
        favoriteToggle.tap()

        // Pop back to Home's feed root before switching tabs — `TabView`
        // keeps each tab's `NavigationStack` alive across tab switches, so
        // leaving the detail screen pushed here would resurface this exact
        // (now-stale) screen the next time this test taps back into Home,
        // instead of the feed `openListingFromHome` expects.
        app.navigationBars.buttons["Home"].tap()

        app.tabBars.firstMatch.buttons["Profile"].tap()
        tap(identifier: "profile.saved-listings", in: app)
        XCTAssertTrue(app.staticTexts[listingTitle].waitForExistence(timeout: 10), "Favorited listing should appear in Saved listings")
    }

    /// Unfavorites by re-tapping the same heart toggle from the listing's
    /// own detail screen (reached by tapping the Saved-listings row), rather
    /// than the row's "Remove" button — `.accessibilityIdentifier("saved-
    /// listing-row.<id>")` is applied to a `VStack` wrapping *two* sibling
    /// buttons (select + Remove), and it resolves to the select button
    /// itself, which has no "Remove" button among its own descendants.
    private func unfavoriteFromSavedListings(app: XCUIApplication) {
        rowElement(identifierPrefix: "saved-listing-row.", containingText: listingTitle, app: app).tap()

        let favoriteToggle = app.buttons["listing-detail.favorite-toggle"]
        XCTAssertTrue(favoriteToggle.waitForExistence(timeout: 10), "Expected tapping the Saved-listings row to open the listing detail screen")
        favoriteToggle.tap()

        app.navigationBars.buttons["Saved"].tap()
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, app.staticTexts[listingTitle].exists {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTAssertFalse(app.staticTexts[listingTitle].exists, "Unfavoriting should remove the listing from Saved listings")

        // Back to the Profile tab root for the next step.
        app.navigationBars.buttons["Profile"].tap()
    }

    private func messageSeller(app: XCUIApplication) {
        let messageSellerButton = app.buttons["listing-detail.message-seller"]
        XCTAssertTrue(messageSellerButton.waitForExistence(timeout: 10))
        messageSellerButton.tap()

        let sendButton = app.buttons["message-thread.send"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10), "Expected to land on the message thread after starting a conversation")

        fillText(identifier: "message-thread.input", text: buyerMessage, app: app)
        sendButton.tap()
        XCTAssertTrue(app.staticTexts[buyerMessage].waitForExistence(timeout: 10), "Sent message should appear in the thread")
    }

    /// Pops back to `ListingDetailView` — its `navigationTitle` ("Listing")
    /// is what the default back button reads regardless of which Phase 6
    /// screen was pushed on top of it (message thread or seller profile).
    private func goBackToListingDetail(app: XCUIApplication) {
        app.navigationBars.buttons["Listing"].tap()
        XCTAssertTrue(app.buttons["listing-detail.seller-profile-link"].waitForExistence(timeout: 10))
    }

    private func viewSellerProfileAndLeaveReview(app: XCUIApplication) {
        let sellerProfileLink = app.buttons["listing-detail.seller-profile-link"]
        XCTAssertTrue(sellerProfileLink.waitForExistence(timeout: 10))
        sellerProfileLink.tap()

        let leaveReviewButton = app.buttons["seller-profile.leave-review"]
        XCTAssertTrue(leaveReviewButton.waitForExistence(timeout: 10), "Expected to land on the seller's public profile")
        leaveReviewButton.tap()

        let star4 = app.buttons["review-composer.star.4"]
        XCTAssertTrue(star4.waitForExistence(timeout: 10))
        star4.tap()

        let submitButton = app.buttons["review-composer.submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()

        XCTAssertTrue(leaveReviewButton.waitForExistence(timeout: 10), "Submitting a review should dismiss the composer sheet back to the seller profile")
    }

    private func replyAsSellerInChat(app: XCUIApplication) {
        app.tabBars.firstMatch.buttons["Chat"].tap()
        let conversationRow = rowElement(identifierPrefix: "conversation-row.", containingText: listingTitle, app: app)
        conversationRow.tap()

        XCTAssertTrue(app.staticTexts[buyerMessage].waitForExistence(timeout: 10), "Seller should see the buyer's message")

        fillText(identifier: "message-thread.input", text: sellerReply, app: app)
        app.buttons["message-thread.send"].tap()
        XCTAssertTrue(app.staticTexts[sellerReply].waitForExistence(timeout: 10), "Seller's reply should appear in the thread")

        // Dismiss the keyboard — it's still up after `fillText`/send (this
        // view has no tap-to-dismiss gesture, so tapping content or nav-bar
        // chrome doesn't resign it), and it covers the tab bar at the bottom
        // of the screen, which makes the next step's tab-bar tap miss.
        app.buttons["Return"].tap()
    }

    private func confirmNotificationReceived(app: XCUIApplication) {
        app.tabBars.firstMatch.buttons["Profile"].tap()
        tap(identifier: "profile.notifications", in: app)

        let notificationRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'notification-row.'"))
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, notificationRows.count == 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTAssertGreaterThan(notificationRows.count, 0, "Expected at least one notification (message/review/favorite) to have been delivered")
    }

    // MARK: - Shared helpers (duplicated from GoldenPathUITests — no shared UITest helper target exists yet)

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
        for identifier in path {
            let node = elementByIdentifier(identifier, in: app)
            XCTAssertTrue(node.waitForExistence(timeout: 10), "Expected category node \(identifier)")
            node.tap()
        }
    }

    private func fillText(identifier: String, text: String, app: XCUIApplication) {
        let field = elementByIdentifier(identifier, in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Expected text field \(identifier)")
        field.tap()
        field.typeText(text)
    }

    private func submitAndExpectReturnToMyListings(app: XCUIApplication) {
        let submit = app.buttons["create-listing.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 10))
        submit.tap()

        var resultRow = app.staticTexts[listingTitle]
        if !resultRow.waitForExistence(timeout: 8) {
            app.scrollViews.firstMatch.swipeDown()
            resultRow = app.staticTexts[listingTitle]
        }
        XCTAssertTrue(resultRow.waitForExistence(timeout: 15), "Expected '\(listingTitle)' to appear in My listings after a successful create")
    }

    private func performOwnerAction(_ action: String, app: XCUIApplication) {
        let row = rowElement(identifierPrefix: "my-listing-row.", containingText: listingTitle, app: app)
        let actionButton = row.buttons[action]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 10), "Expected '\(action)' action on the row for '\(listingTitle)'")
        actionButton.tap()
    }

    /// Returns the first matching row (by declaration order in the
    /// accessibility tree) whose identifier starts with `identifierPrefix`
    /// and which contains `text` — freshly-created/updated rows surface
    /// first in every list this test touches (My listings, Saved listings,
    /// Chat's conversation list), consistent with `GoldenPathUITests`'s
    /// `rowElement` helper.
    private func rowElement(identifierPrefix: String, containingText text: String, app: XCUIApplication) -> XCUIElement {
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", identifierPrefix))
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            let count = rows.count
            for i in 0..<count {
                let row = rows.element(boundBy: i)
                if row.staticTexts[text].exists {
                    return row
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("No row with prefix '\(identifierPrefix)' found containing '\(text)'")
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
