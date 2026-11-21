import SwiftUI

/// One colour of the modern look: its own value in light mode and in dark mode, each
/// written 0xRRGGBB. The two are chosen separately, never one inverted from the other.
struct AdaptiveColor: Sendable {
    let light: UInt32
    let dark: UInt32
    /// Follows the colour scheme of whatever view draws it.
    let color: Color

    init(light: UInt32, dark: UInt32) {
        self.light = light
        self.dark = dark
        color = Color(uiColor: UIColor { traits in
            UIColor(redGreenBlue: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// A colour that is the same in both modes.
    init(_ both: UInt32) {
        self.init(light: both, dark: both)
    }
}

extension UIColor {
    /// An opaque colour from 0xRRGGBB.
    fileprivate convenience init(redGreenBlue: UInt32) {
        self.init(
            red: CGFloat((redGreenBlue >> 16) & 0xFF) / 255,
            green: CGFloat((redGreenBlue >> 8) & 0xFF) / 255,
            blue: CGFloat(redGreenBlue & 0xFF) / 255,
            alpha: 1)
    }
}

/// Every colour the modern look uses. Each 0xRRGGBB value is written once: a colour that
/// shares a value with another takes it from that colour. `ModernPaletteTests` holds the
/// text here to WCAG AA contrast (4.5 to 1) against what it is drawn on, and the symbols
/// and pieces that carry meaning to 3 to 1.
enum ModernPalette {
    // Text.
    static let textPrimary = AdaptiveColor(light: 0x1F1B3D, dark: 0xF3F2FF)
    static let textSecondary = AdaptiveColor(light: 0x5C5980, dark: 0xB7B4DA)
    static let accentFill = AdaptiveColor(light: 0x5B4BE0, dark: 0x6554E8)
    static let accentText = AdaptiveColor(light: 0x4A3AC7, dark: 0xB9AEFF)
    static let titleStart = AdaptiveColor(light: accentFill.light, dark: 0xA99BFF)
    static let titleEnd = AdaptiveColor(light: 0xA626B8, dark: 0xF08BFF)
    /// Text and symbols drawn on a filled, coloured shape.
    static let onColor = AdaptiveColor(0xFFFFFF)

    // The screen and the cards that sit on it.
    static let screenTop = AdaptiveColor(light: 0xF3F0FF, dark: 0x15132E)
    static let screenBottom = AdaptiveColor(light: 0xE6F1FF, dark: 0x0D1B2E)
    static let surface = AdaptiveColor(light: onColor.light, dark: 0x23213F)
    static let surfaceStroke = AdaptiveColor(light: 0xDCD9F2, dark: 0x37355F)
    static let shadow = AdaptiveColor(light: textPrimary.light, dark: 0x000000)

    // The board.
    static let boardBase = AdaptiveColor(light: 0xE3E1F5, dark: 0x17162F)
    static let boardTile = AdaptiveColor(light: 0xF8F7FF, dark: 0x26244A)
    static let boardStroke = AdaptiveColor(light: 0xC9C5EA, dark: 0x3F3D70)
    static let safeMove = AdaptiveColor(light: 0x0B7F3F, dark: 0x3DDC84)
    /// How strongly a safe square is washed with `safeMove` under its outline and dot.
    static let safeMoveFillOpacity = 0.18

    // Robots: warm, the one red thing on the board.
    static let robotBodyTop = AdaptiveColor(light: 0xE94A44, dark: 0xFF8A7A)
    static let robotBodyBottom = AdaptiveColor(light: 0xD7263D, dark: 0xF0443A)
    static let robotTrim = AdaptiveColor(light: 0x8E1B2E, dark: 0xD0505C)
    static let robotVisor = AdaptiveColor(light: 0x3B1026, dark: 0x2A0B1B)
    static let robotEye = AdaptiveColor(0xFFF1A8)
    static let robotLamp = AdaptiveColor(light: 0xFFC83D, dark: 0xFFD45E)

    // The player: blue, and so is the pulse, which is the player's own power.
    static let playerBodyTop = AdaptiveColor(light: 0x3F7BF5, dark: 0x7FB0FF)
    static let playerBodyBottom = AdaptiveColor(light: 0x1D4FD8, dark: 0x3D7BFF)
    static let playerHelmet = AdaptiveColor(light: onColor.light, dark: 0xF2F6FF)
    static let playerVisor = AdaptiveColor(light: 0x12306E, dark: 0x0F2A66)
    /// The ring around the player: the darker blue on a light tile, the lighter on a dark.
    static let playerRing = AdaptiveColor(light: playerBodyBottom.light, dark: playerBodyTop.dark)
    /// How strongly the inside of the ring is washed with `playerBodyTop`.
    static let playerRingFillOpacity = 0.2

    // Scrap: cold metal with one brass gear.
    static let scrapLight = AdaptiveColor(light: 0x7E869D, dark: 0xBCC3D6)
    static let scrapMiddle = AdaptiveColor(light: 0x656E86, dark: 0x9AA2B8)
    static let scrapDark = AdaptiveColor(light: 0x464E64, dark: 0x7A829C)
    static let scrapBrass = AdaptiveColor(light: 0xC98F1E, dark: 0xE8B85A)

    // The three actions. A white symbol sits on each, so both ends stay dark enough.
    static let teleportStart = AdaptiveColor(0x8B5CF6)
    static let teleportEnd = AdaptiveColor(0x6D28D9)
    static let pulseStart = AdaptiveColor(0x0284C7)
    static let pulseEnd = AdaptiveColor(0x0369A1)
    static let lastStandStart = AdaptiveColor(0xE8590C)
    static let lastStandEnd = AdaptiveColor(0xC2410C)

    // Scoreboard icons.
    static let statLevel = AdaptiveColor(light: 0x2F6BFF, dark: playerBodyTop.dark)
    static let statScore = AdaptiveColor(light: 0xB85F00, dark: 0xFBBF24)
    static let statBest = AdaptiveColor(light: 0x7C4DEE, dark: 0xC4B5FD)

    // A good outcome (a cleared level, hints switched on) and a bad one (caught).
    static let positiveStart = AdaptiveColor(0x0A7D57)
    static let positiveEnd = AdaptiveColor(0x0A6F78)
    static let positiveText = AdaptiveColor(light: 0x0B6B4F, dark: 0x4ADE9A)
    static let negativeStart = AdaptiveColor(0xD41645)
    static let negativeEnd = AdaptiveColor(0x9D2BD1)
    static let negativeText = AdaptiveColor(light: 0xC0143C, dark: 0xFF8FA3)
}
