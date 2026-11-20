import SwiftUI

extension LegacyTheme {
    /// PLACEHOLDER, not the modern design. Until the real modern theme is written (its
    /// own `Theme` type, in this file), the modern style is the legacy drawing in one
    /// accent colour: enough to show the setting switching themes live, and nothing more.
    static let modernPlaceholder = LegacyTheme(
        palette: OneBitPalette(ink: Color.indigo, paper: OneBitPalette.classic.paper))
}
