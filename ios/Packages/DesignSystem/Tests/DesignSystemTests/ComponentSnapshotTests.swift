#if canImport(UIKit)
import Testing
import Foundation
import SwiftUI
@testable import Configuration
import SnapshotTesting
@testable import DesignSystem

// Real device rendering, not macOS's AppKit approximation — run these via
// `xcodebuild test -destination 'platform=iOS Simulator,name=...'`, not plain
// `swift test` (which builds for macOS and would render through a different
// host entirely). A small curated set (09-cross-cutting.md §"Representative-
// config matrix"), not every component × theme × locale combination.

@Suite(.serialized)
@MainActor
struct ComponentSnapshotTests {
    func render<V: View>(_ view: V, colorScheme: ColorScheme, layoutDirection: LayoutDirection = .leftToRight) -> UIViewController {
        let host = UIHostingController(
            rootView: ThemedRoot(theme: Theme.resolve(from: try! BundledDefaults.theme())) {
                view
            }
            .environment(\.colorScheme, colorScheme)
            .environment(\.layoutDirection, layoutDirection)
            .frame(width: 320, height: 120)
        )
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        return host
    }

    @Test func primaryButtonLight() {
        let vc = render(PrimaryButton("Publish listing", action: {}), colorScheme: .light)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    @Test func primaryButtonDark() {
        let vc = render(PrimaryButton("Publish listing", action: {}), colorScheme: .dark)
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }

    @Test func cardRTL() {
        let vc = render(
            Card { Text("منشور جديد") },
            colorScheme: .light,
            layoutDirection: .rightToLeft
        )
        assertSnapshot(of: vc, as: .image, record: ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil)
    }
}
#endif
