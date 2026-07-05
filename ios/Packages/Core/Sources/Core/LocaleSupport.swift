import Foundation

/// A locale the platform-neutral Development Schema can name (e.g. `configs/`'s
/// `locales` array) without dragging in SwiftUI's `LayoutDirection` at this
/// layer — `DesignSystem` maps this to `LayoutDirection` for the view tree.
public struct AppLocale: Equatable, Sendable, Codable, Identifiable {
    public let identifier: String
    public let isRTL: Bool

    public var id: String { identifier }

    public init(identifier: String) {
        self.identifier = identifier
        self.isRTL = Locale.Language(identifier: identifier).characterDirection == .rightToLeft
    }

    public static let english = AppLocale(identifier: "en")
    public static let arabic = AppLocale(identifier: "ar")
}
