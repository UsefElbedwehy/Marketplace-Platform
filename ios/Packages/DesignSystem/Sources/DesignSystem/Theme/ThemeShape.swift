import Foundation
import Configuration

/// Corner-radius tokens from `theme.json`'s `shape` section. Named
/// `ThemeShape` (not `Shape`) to avoid colliding with SwiftUI's `Shape`
/// protocol.
public struct ThemeShape: Equatable {
    public let cornerRadiusSmall: CGFloat
    public let cornerRadiusMedium: CGFloat
    public let cornerRadiusLarge: CGFloat

    static func resolve(from dto: ThemeDTO.Shape) -> ThemeShape {
        ThemeShape(
            cornerRadiusSmall: dto.cornerRadiusSmall,
            cornerRadiusMedium: dto.cornerRadiusMedium,
            cornerRadiusLarge: dto.cornerRadiusLarge
        )
    }
}
