import Testing
import SwiftUI
@testable import DesignSystem

@Test func hexColorParsesSixDigitHex() {
    #expect(Color(hex: "#2563EB") != nil)
}

@Test func hexColorParsesEightDigitHexWithAlpha() {
    #expect(Color(hex: "#0F172A99") != nil)
}

@Test func hexColorParsesWithoutLeadingHash() {
    #expect(Color(hex: "2563EB") != nil)
}

@Test func hexColorReturnsNilForInvalidLength() {
    #expect(Color(hex: "#FFF") == nil)
}

@Test func hexColorReturnsNilForNonHexCharacters() {
    #expect(Color(hex: "#ZZZZZZ") == nil)
}
