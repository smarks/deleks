import SwiftUI
import Testing

@testable import deleks

/// Holds the modern palette to WCAG 2 contrast, in light mode and in dark mode: 4.5 to 1
/// for text against what it is drawn on (level AA), and 3 to 1 for everything that is not
/// text but carries meaning: the symbols on badges, the stat icons, the safe-square mark
/// and the pieces on the board.
@Suite("Modern palette")
struct ModernPaletteTests {
    /// A foreground and what it is drawn on. Some backgrounds are a surface washed with a
    /// translucent colour; `wash` and `washOpacity` describe that.
    struct ColorPair: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let foreground: AdaptiveColor
        let background: AdaptiveColor
        let wash: AdaptiveColor?
        let washOpacity: Double

        init(
            _ what: String, _ foreground: AdaptiveColor, on background: AdaptiveColor,
            washedWith wash: AdaptiveColor? = nil, opacity washOpacity: Double = 0
        ) {
            testDescription = what
            self.foreground = foreground
            self.background = background
            self.wash = wash
            self.washOpacity = washOpacity
        }

        var lightContrast: Double {
            let shownBehind = ModernPaletteTests.washed(
                background.light, with: wash?.light, opacity: washOpacity)
            return ModernPaletteTests.contrast(foreground.light, shownBehind)
        }

        var darkContrast: Double {
            let shownBehind = ModernPaletteTests.washed(
                background.dark, with: wash?.dark, opacity: washOpacity)
            return ModernPaletteTests.contrast(foreground.dark, shownBehind)
        }
    }

    static let textPairs = [
        ColorPair(
            "stat values, action titles and unselected pills",
            ModernPalette.textPrimary, on: ModernPalette.surface),
        ColorPair(
            "stat labels and the card's detail line",
            ModernPalette.textSecondary, on: ModernPalette.surface),
        ColorPair(
            "title, gradient start, top of the screen",
            ModernPalette.titleStart, on: ModernPalette.screenTop),
        ColorPair(
            "title, gradient end, top of the screen",
            ModernPalette.titleEnd, on: ModernPalette.screenTop),
        ColorPair(
            "title, gradient start, bottom of the screen",
            ModernPalette.titleStart, on: ModernPalette.screenBottom),
        ColorPair(
            "title, gradient end, bottom of the screen",
            ModernPalette.titleEnd, on: ModernPalette.screenBottom),
        ColorPair(
            "the Modern look pill when on", ModernPalette.onColor, on: ModernPalette.accentFill),
        ColorPair(
            "the hints pill when on", ModernPalette.onColor, on: ModernPalette.positiveStart),
        ColorPair("the New game pill", ModernPalette.accentText, on: ModernPalette.surface),
        ColorPair(
            "the cleared card's heading", ModernPalette.positiveText, on: ModernPalette.surface),
        ColorPair(
            "the caught card's heading", ModernPalette.negativeText, on: ModernPalette.surface),
        ColorPair(
            "the cleared card's button, gradient start",
            ModernPalette.onColor, on: ModernPalette.positiveStart),
        ColorPair(
            "the cleared card's button, gradient end",
            ModernPalette.onColor, on: ModernPalette.positiveEnd),
        ColorPair(
            "the caught card's button, gradient start",
            ModernPalette.onColor, on: ModernPalette.negativeStart),
        ColorPair(
            "the caught card's button, gradient end",
            ModernPalette.onColor, on: ModernPalette.negativeEnd),
    ]

    static let meaningfulShapePairs = [
        ColorPair("Teleport symbol, top", ModernPalette.onColor, on: ModernPalette.teleportStart),
        ColorPair("Teleport symbol, bottom", ModernPalette.onColor, on: ModernPalette.teleportEnd),
        ColorPair("Pulse symbol, top", ModernPalette.onColor, on: ModernPalette.pulseStart),
        ColorPair("Pulse symbol, bottom", ModernPalette.onColor, on: ModernPalette.pulseEnd),
        ColorPair(
            "Last stand symbol, top", ModernPalette.onColor, on: ModernPalette.lastStandStart),
        ColorPair(
            "Last stand symbol, bottom", ModernPalette.onColor, on: ModernPalette.lastStandEnd),
        ColorPair("the Level icon", ModernPalette.statLevel, on: ModernPalette.surface),
        ColorPair("the Score icon", ModernPalette.statScore, on: ModernPalette.surface),
        ColorPair("the Best icon", ModernPalette.statBest, on: ModernPalette.surface),
        ColorPair(
            "a safe square's outline against the bare tile",
            ModernPalette.safeMove, on: ModernPalette.boardTile),
        ColorPair(
            "a safe square's outline and dot against its own green wash",
            ModernPalette.safeMove, on: ModernPalette.boardTile,
            washedWith: ModernPalette.safeMove, opacity: ModernPalette.safeMoveFillOpacity),
        ColorPair(
            "a robot, top of its shell", ModernPalette.robotBodyTop, on: ModernPalette.boardTile),
        ColorPair(
            "a robot, bottom of its shell",
            ModernPalette.robotBodyBottom, on: ModernPalette.boardTile),
        ColorPair("a robot's limbs", ModernPalette.robotTrim, on: ModernPalette.boardTile),
        ColorPair(
            "the player's suit, top", ModernPalette.playerBodyTop, on: ModernPalette.boardTile),
        ColorPair(
            "the player's suit and helmet outline",
            ModernPalette.playerBodyBottom, on: ModernPalette.boardTile),
        ColorPair(
            "the player's ring against its own wash",
            ModernPalette.playerRing, on: ModernPalette.boardTile,
            washedWith: ModernPalette.playerBodyTop,
            opacity: ModernPalette.playerRingFillOpacity),
        ColorPair("scrap, the mound", ModernPalette.scrapLight, on: ModernPalette.boardTile),
        ColorPair(
            "scrap, the tall plate", ModernPalette.scrapMiddle, on: ModernPalette.boardTile),
        ColorPair("scrap, the back plate", ModernPalette.scrapDark, on: ModernPalette.boardTile),
    ]

    @Test(arguments: textPairs)
    func textIsReadableInBothModes(pair: ColorPair) {
        let minimumForText = 4.5
        #expect(pair.lightContrast >= minimumForText)
        #expect(pair.darkContrast >= minimumForText)
    }

    @Test(arguments: meaningfulShapePairs)
    func shapesThatCarryMeaningStandOutInBothModes(pair: ColorPair) {
        let minimumForShapes = 3.0
        #expect(pair.lightContrast >= minimumForShapes)
        #expect(pair.darkContrast >= minimumForShapes)
    }

    /// The measure itself, checked against the two values WCAG fixes by definition.
    @Test func contrastRunsFromOneToTwentyOne() {
        let tolerance = 0.000_001
        #expect(abs(Self.contrast(0x000000, 0xFFFFFF) - 21) < tolerance)
        #expect(abs(Self.contrast(0x777777, 0x777777) - 1) < tolerance)
    }

    /// A wash at half strength lands midway between the two colours, channel by channel.
    @Test func aWashMixesTheTwoColors() {
        #expect(Self.washed(0x000000, with: 0xFFFFFF, opacity: 0.5) == 0x808080)
        #expect(Self.washed(0x204060, with: nil, opacity: 0.5) == 0x204060)
    }

    /// The numbers above are only the truth if each colour really shows its light value in
    /// light mode and its dark value in dark mode.
    @Test @MainActor func aColorShowsItsLightValueInLightModeAndItsDarkValueInDarkMode() {
        let sample = AdaptiveColor(light: 0x112233, dark: 0xAABBCC)
        #expect(Self.shown(sample, in: .light) == sample.light)
        #expect(Self.shown(sample, in: .dark) == sample.dark)

        let same = AdaptiveColor(0x445566)
        #expect(Self.shown(same, in: .light) == 0x445566)
        #expect(Self.shown(same, in: .dark) == 0x445566)

        let surface = ModernPalette.surface
        #expect(Self.shown(surface, in: .light) == surface.light)
        #expect(Self.shown(surface, in: .dark) == surface.dark)
    }

    /// The 0xRRGGBB a colour resolves to under one interface style.
    @MainActor private static func shown(
        _ color: AdaptiveColor, in style: UIUserInterfaceStyle
    ) -> UInt32 {
        let resolved = UIColor(color.color)
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        let channels = [red, green, blue].map { UInt32(($0 * 255).rounded()) }
        return channels[0] << 16 | channels[1] << 8 | channels[2]
    }

    /// `base` with `wash` laid over it at `opacity`, as 0xRRGGBB.
    fileprivate static func washed(_ base: UInt32, with wash: UInt32?, opacity: Double) -> UInt32 {
        guard let wash else { return base }
        return [16, 8, 0].reduce(UInt32(0)) { mixed, shift in
            let over = Double((wash >> UInt32(shift)) & 0xFF)
            let under = Double((base >> UInt32(shift)) & 0xFF)
            let channel = UInt32((over * opacity + under * (1 - opacity)).rounded())
            return mixed | channel << UInt32(shift)
        }
    }

    /// WCAG 2 contrast ratio of two 0xRRGGBB colours.
    fileprivate static func contrast(_ first: UInt32, _ second: UInt32) -> Double {
        let lighter = max(relativeLuminance(first), relativeLuminance(second))
        let darker = min(relativeLuminance(first), relativeLuminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ redGreenBlue: UInt32) -> Double {
        let linearChannels = [16, 8, 0].map { shift -> Double in
            let channel = Double((redGreenBlue >> UInt32(shift)) & 0xFF) / 255
            return channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearChannels[0] + 0.7152 * linearChannels[1]
            + 0.0722 * linearChannels[2]
    }
}
