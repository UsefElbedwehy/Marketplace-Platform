import SwiftUI
import Configuration

/// A named text style — `size`/`weight`/`lineHeight` from `theme.json`'s
/// `typography.scale`, resolved into a real SwiftUI `Font`.
public struct TextStyle: Equatable {
    public let font: Font
    public let lineHeight: CGFloat
}

public struct Typography: Equatable {
    public let largeTitle: TextStyle
    public let title1: TextStyle
    public let title2: TextStyle
    public let headline: TextStyle
    public let body: TextStyle
    public let subheadline: TextStyle
    public let caption: TextStyle
    public let footnote: TextStyle

    static func resolve(from dto: ThemeDTO.Typography) -> Typography {
        func style(_ key: String, fallbackSize: CGFloat, fallbackWeight: Font.Weight) -> TextStyle {
            guard let entry = dto.scale[key] else {
                return TextStyle(font: .system(size: fallbackSize, weight: fallbackWeight), lineHeight: fallbackSize * 1.2)
            }
            return TextStyle(
                font: .custom(dto.fontFamily, size: entry.size).weight(weight(from: entry.weight)),
                lineHeight: entry.lineHeight
            )
        }
        return Typography(
            largeTitle: style("largeTitle", fallbackSize: 34, fallbackWeight: .bold),
            title1: style("title1", fallbackSize: 28, fallbackWeight: .bold),
            title2: style("title2", fallbackSize: 22, fallbackWeight: .semibold),
            headline: style("headline", fallbackSize: 17, fallbackWeight: .semibold),
            body: style("body", fallbackSize: 17, fallbackWeight: .regular),
            subheadline: style("subheadline", fallbackSize: 15, fallbackWeight: .regular),
            caption: style("caption", fallbackSize: 12, fallbackWeight: .regular),
            footnote: style("footnote", fallbackSize: 13, fallbackWeight: .regular)
        )
    }

    private static func weight(from name: String) -> Font.Weight {
        switch name {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        default: return .regular
        }
    }
}
