import XCTest

/// Roadmap Phase 4 exit criterion ⭐: "edit a schema server-side → app
/// reflects it after refresh, no rebuild." Edits the real local Postgres
/// catalog through the actual `catalog_editor`-gated write API (not a direct
/// SQL poke) while the app is already running, then proves the running
/// `CreateListingView` picks up the new field on a plain re-fetch — no
/// Simulator relaunch, no rebuild.
@MainActor
final class SchemaLiveEditUITests: XCTestCase {
    private let phonesAttributeGroupId = "b1000000-0000-0000-0000-000000000005"

    func testEditingASchemaServerSideReflectsInTheRunningAppWithoutARebuild() async throws {
        // Unique per run (no DELETE-attribute route exists on the contract —
        // schema edits are additive in the real product — so reruns just get
        // a fresh key instead of needing cleanup against the unique
        // (group_id, key) constraint).
        let newFieldKey = "goldenPathWarranty\(Int(Date().timeIntervalSince1970))"

        let app = XCUIApplication()
        app.launch()
        signIn(as: "seller", app: app)

        app.tabBars.firstMatch.buttons["Sell"].tap()
        let newListingButton = app.buttons["sell.new-listing"]
        XCTAssertTrue(newListingButton.waitForExistence(timeout: 10))
        newListingButton.tap()
        selectCategory(path: ["category.electronics", "category.phones"], app: app)

        let probeFieldBefore = elementByIdentifier("dynamic-field.\(newFieldKey)", in: app)
        XCTAssertTrue(app.buttons["create-listing.submit"].waitForExistence(timeout: 10))
        XCTAssertFalse(probeFieldBefore.exists, "The probe field shouldn't exist before the server-side schema edit")

        // The server-side schema edit — through the real catalog_editor
        // write API, the same path the dashboard's Schema Builder uses.
        try await Self.addProbeAttribute(key: newFieldKey, groupId: phonesAttributeGroupId)

        // No rebuild, no relaunch: re-opening the category picker (which
        // always starts back at the tree root) and re-selecting the same
        // leaf category is the app's own affordance for re-fetching a
        // schema (mirrors `CreateListingViewModel.refreshSchema()`,
        // exercised at the unit level already).
        selectCategory(path: ["category.electronics", "category.phones"], app: app)

        let probeFieldAfter = elementByIdentifier("dynamic-field.\(newFieldKey)", in: app)
        XCTAssertTrue(probeFieldAfter.waitForExistence(timeout: 15), "The new attribute should appear after refetching the schema, with no rebuild")
    }

    // MARK: - Server-side schema edit via the real API

    private static func mintCatalogEditorToken() async throws -> String {
        var request = URLRequest(url: URL(string: "http://localhost:8000/v1/dev-auth")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "sub": "90000001-0000-0000-0000-000000000003",
            "role": "authenticated",
            "app_role": "catalog_editor",
            "tenant_id": "00000000-0000-0000-0000-000000000001",
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = (json?["data"] as? [String: Any])?["accessToken"] as? String else {
            throw NSError(domain: "SchemaLiveEditUITests", code: 1, userInfo: [NSLocalizedDescriptionKey: "No accessToken in dev-auth response: \(json ?? [:])"])
        }
        return token
    }

    private static func addProbeAttribute(key: String, groupId: String) async throws {
        let token = try await mintCatalogEditorToken()
        var request = URLRequest(url: URL(string: "http://localhost:8000/v1/attribute-groups/\(groupId)/attributes")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "key": key,
            "labelI18n": ["en": "Golden Path Warranty"],
            "dataType": "number",
            "inputType": "stepper",
            "isRequired": false,
            "isFilterable": true,
            "isSearchable": false,
            "sortOrder": 99,
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 201 else {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw NSError(domain: "SchemaLiveEditUITests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create attribute (status \(status)): \(body)"])
        }
    }

    // MARK: - Shared steps (mirrors GoldenPathUITests)

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

    private func elementByIdentifier(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

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
                return
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
