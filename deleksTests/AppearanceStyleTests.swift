import Testing

@testable import deleks

@Suite("Appearance style")
struct AppearanceStyleTests {
    @Test func theGameStartsInTheLegacyLook() {
        #expect(AppearanceStyle.initial == .legacy)
    }

    /// The saved setting and the `-appearanceStyle` launch argument both use these names.
    @Test func stylesAreSavedUnderTheirNames() {
        #expect(AppearanceStyle.legacy.rawValue == "legacy")
        #expect(AppearanceStyle.modern.rawValue == "modern")
        #expect(AppearanceStyle.allCases == [.legacy, .modern])
        #expect(StorageKey.appearanceStyle == "appearanceStyle")
    }

    @Test func eachStyleIsDrawnByItsOwnTheme() {
        #expect(AppearanceStyle.legacy.theme is LegacyTheme)
        #expect(AppearanceStyle.modern.theme is ModernTheme)
    }

    @Test func modernIsTheOnlyStyleTheToggleShowsAsOn() {
        #expect(AppearanceStyle.modern.isModern)
        #expect(!AppearanceStyle.legacy.isModern)
    }

    @Test func turningTheToggleOnAndOffPicksTheStyle() {
        var style = AppearanceStyle.legacy
        style.isModern = true
        #expect(style == .modern)
        style.isModern = false
        #expect(style == .legacy)
    }
}
