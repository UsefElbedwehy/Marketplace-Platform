import SwiftUI

extension Color {
    /// Parses the hex strings `theme.json` ships (`#RRGGBB` or `#RRGGBBAA`,
    /// e.g. `colors.light.overlay` = `"#0F172A99"`). Returns `nil` (never
    /// crashes) on malformed input — callers fall back to a visible "this
    /// theme is broken" placeholder rather than raw-literal-in-DesignSystem,
    /// which stays the one enforced exception (`ThemeShape`'s magenta
    /// placeholder color, see `SemanticColors.resolve`).
    init?(hex: String) {
        var value = hex
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6 || value.count == 8 else { return nil }
        guard let intValue = UInt64(value, radix: 16) else { return nil }

        let r, g, b, a: UInt64
        if value.count == 8 {
            (r, g, b, a) = ((intValue >> 24) & 0xFF, (intValue >> 16) & 0xFF, (intValue >> 8) & 0xFF, intValue & 0xFF)
        } else {
            (r, g, b, a) = ((intValue >> 16) & 0xFF, (intValue >> 8) & 0xFF, intValue & 0xFF, 0xFF)
        }
        self = Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
