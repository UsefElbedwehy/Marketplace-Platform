import Testing
@testable import Core

@Test func arabicIsFlaggedRTL() {
    #expect(AppLocale.arabic.isRTL == true)
}

@Test func englishIsNotRTL() {
    #expect(AppLocale.english.isRTL == false)
}
