import SwiftUI

/// How one appearance style draws every surface of the game. The views in
/// `ContentView` and `BoardView` own layout, game state and accessibility; they ask the
/// theme in the environment for anything that has a look, and never test which style is
/// active.
///
/// A theme supplies pictures and motion only. Every accessibility identifier, label,
/// value and trait is set by the calling view, on what the theme returns or on a view the
/// caller hands the theme to place (a "slot": the title, and the card's heading, detail
/// and button). A theme styles a slot with modifiers such as `font` and
/// `foregroundStyle` and shows it once; it never replaces it with text of its own.
/// Whatever a theme draws for the screen and board backgrounds, the hints and the border
/// is hidden from accessibility by the caller.
protocol Theme: Sendable {
    /// Font design applied to the whole screen.
    var fontDesign: Font.Design { get }
    /// Default fill of text and symbols: a colour, a gradient or any other shape style.
    var textStyle: AnyShapeStyle { get }
    /// The gap between rows of the settings controls when they wrap onto more than one.
    var settingRowSpacing: CGFloat { get }

    // Motion is asked for on the main actor, where a theme can read the Reduce Motion
    // setting and move less when it is on.

    /// How the board moves from one turn or level to the next.
    @MainActor var turnAnimation: Animation { get }
    /// How a scrap heap arrives on the board.
    @MainActor var heapTransition: AnyTransition { get }
    /// How a robot leaves the board when it is scrapped.
    @MainActor var robotTransition: AnyTransition { get }

    /// Fills the screen behind everything, safe areas included.
    @MainActor func screenBackground() -> AnyView
    /// The bar across the top. `title` is a slot.
    @MainActor func titleBar(title: AnyView) -> AnyView

    /// Lays out the stats, each already built by `scoreboardStat`, in the order given.
    @MainActor func scoreboard(stats: [AnyView]) -> AnyView
    @MainActor func scoreboardStat(
        role: StatRole, label: LocalizedStringKey, value: Int
    ) -> AnyView

    /// The playing field under the pieces, `columns` by `rows` cells of `cellSize` points.
    @MainActor func boardBackground(columns: Int, rows: Int, cellSize: CGFloat) -> AnyView
    /// Drawn over the board, pieces included, at the board's exact size.
    @MainActor func boardBorder() -> AnyView

    // The hint and the pieces. Each comes back at the size it should have in a cell
    // `cellSize` points square; the board only places it at the cell's centre.

    /// Marks a square no robot can reach next turn.
    @MainActor func safeMoveHint(cellSize: CGFloat) -> AnyView
    @MainActor func robotGlyph(cellSize: CGFloat) -> AnyView
    @MainActor func heapGlyph(cellSize: CGFloat) -> AnyView
    /// The player, shown as caught once a robot has reached them.
    @MainActor func playerGlyph(cellSize: CGFloat, isCaught: Bool) -> AnyView

    /// One of the three big action buttons. Dims itself when disabled. `title` can change
    /// from turn to turn (Pulse shows its charges); `role` says which button it is.
    @MainActor func actionButton(
        role: ActionRole, title: String, systemImage: String, action: @escaping () -> Void
    ) -> AnyView
    /// An on/off setting in the row under the action buttons. It must be a `Toggle`, in
    /// any toggle style, so that it reports its own on/off state to accessibility.
    @MainActor func settingToggle(
        role: SettingRole, title: LocalizedStringKey, isOn: Binding<Bool>
    ) -> AnyView
    /// A lesser button in the row under the action buttons.
    @MainActor func secondaryButton(
        title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView

    /// The card over the board when a level ends. `heading`, `detail` and `actionButton`
    /// are slots; `actionButton` comes from `resultActionButton`.
    @MainActor func resultCard(
        outcome: LevelOutcome, heading: AnyView, detail: AnyView, actionButton: AnyView
    ) -> AnyView
    @MainActor func resultActionButton(
        outcome: LevelOutcome, title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView
}

/// Which of the three actions a button performs, so a theme can give each its own look.
enum ActionRole {
    case teleport
    case pulse
    case lastStand
}

/// Which figure a scoreboard stat shows.
enum StatRole {
    case level
    case score
    case best
    case robots
}

/// Which setting a toggle changes.
enum SettingRole {
    case safeMoveHints
    case modernLook
}

/// How a level ended, for the surfaces that look different after a win and a loss.
enum LevelOutcome {
    case cleared
    case caught
}

extension EnvironmentValues {
    /// The theme of the active appearance style. `ContentView` sets it from the setting.
    @Entry var theme: any Theme = AppearanceStyle.initial.theme
}

extension AppearanceStyle {
    /// The one place a style is turned into the theme that draws it.
    var theme: any Theme {
        switch self {
        case .legacy: LegacyTheme()
        case .modern: ModernTheme()
        }
    }

    /// The style as an on/off choice, for the "Modern look" toggle.
    var isModern: Bool {
        get { self == .modern }
        set { self = newValue ? .modern : .legacy }
    }
}
