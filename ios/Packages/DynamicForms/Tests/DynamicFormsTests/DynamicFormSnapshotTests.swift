#if canImport(UIKit)
import Testing
import Foundation
import SwiftUI
@testable import Configuration
import SnapshotTesting
import DomainKit
@testable import DesignSystem
@testable import DynamicForms

// Real device rendering (UIKit), not macOS's AppKit approximation — run via
// `xcodebuild test -destination 'platform=iOS Simulator,name=...'`, not plain
// `swift test`. Roadmap Phase 4's third exit criterion: DynamicForms
// snapshot tests across verticals × {LTR/RTL} × {light/dark}. A small
// curated matrix (mirrors DesignSystem's ComponentSnapshotTests precedent),
// not every field-type × theme × locale combination.

@Suite(.serialized)
@MainActor
struct DynamicFormSnapshotTests {
    func render<V: View>(_ view: V, colorScheme: ColorScheme, layoutDirection: LayoutDirection = .leftToRight) -> UIViewController {
        let host = UIHostingController(
            rootView: ThemedRoot(theme: Theme.resolve(from: try! BundledDefaults.theme())) {
                ScrollView { view.padding(16) }
            }
            .environment(\.colorScheme, colorScheme)
            .environment(\.layoutDirection, layoutDirection)
            .frame(width: 375, height: 700)
        )
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 700)
        return host
    }

    @Test func carsFormLight() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        let vc = render(DynamicFormView(state: state), colorScheme: .light)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    @Test func carsFormDark() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        let vc = render(DynamicFormView(state: state), colorScheme: .dark)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    @Test func carsFormRTL() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        let vc = render(DynamicFormView(state: state), colorScheme: .light, layoutDirection: .rightToLeft)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    /// The structurally-different vertical: no option/dropdown fields, no
    /// dependencies — proves the same `DynamicFormView` renders a completely
    /// different shape from metadata alone, not vertical-specific code.
    @Test func apartmentsFormLight() {
        let state = DynamicFormState(schema: ApartmentsSchemaFixture.schema)
        let vc = render(DynamicFormView(state: state), colorScheme: .light)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    @Test func apartmentsFormRTLDark() {
        let state = DynamicFormState(schema: ApartmentsSchemaFixture.schema)
        let vc = render(DynamicFormView(state: state), colorScheme: .dark, layoutDirection: .rightToLeft)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }
}
#endif
