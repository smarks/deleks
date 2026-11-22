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
    /// `accessory`, a slot, goes at the bar's leading end in the room beside the title,
    /// through `TitleBarWithLeadingAccessory`: it never changes the bar's size or reaches
    /// the title, and the title gives up centring where that room is too small to touch.
    @MainActor func titleBar(title: AnyView, accessory: AnyView) -> AnyView

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

    // The About box. Its wording comes from `About.json`, so titles arrive as plain
    // strings to show as they are.

    /// The button that opens the About box, the title bar's accessory.
    /// It sits in the title bar's room beside the title, which can be narrow (a 320-point
    /// window at the largest text size), so it must fit any width it is offered: by
    /// scaling its title down, for example, never by spilling past its frame.
    @MainActor func aboutButton(title: String, action: @escaping () -> Void) -> AnyView
    /// Covers the whole screen behind the About box. The caller stretches it over the
    /// safe areas, lets it take every touch so the game cannot be played under the box,
    /// and hides it from accessibility.
    @MainActor func aboutScrim() -> AnyView
    /// The About box. `heading`, `version`, every section and `doneButton` are slots;
    /// `doneButton` comes from `aboutDoneButton`. The sections go below the heading and
    /// the version in the order given, and scroll whenever they are taller than the room
    /// the box has (`scrollingWhenTaller()`), so no text is cut short at any text size.
    /// `doneButton` stays in view below them, never scrolled away.
    @MainActor func aboutBox(
        heading: AnyView, version: AnyView, sections: [AnyView], doneButton: AnyView
    ) -> AnyView
    @MainActor func aboutDoneButton(title: String, action: @escaping () -> Void) -> AnyView
    /// A web link in the About box. It must be a `Link`, so accessibility announces it as
    /// a link.
    @MainActor func aboutLink(title: String, destination: URL) -> AnyView
    /// Shows `content` only while `isExpanded`, under `label`; both are slots. It must be
    /// a `DisclosureGroup`, so accessibility hears whether it is open. The caller marks
    /// the label and the content each with its own identifier, since one set on the whole
    /// group would replace the content's.
    @MainActor func aboutDisclosure(
        label: AnyView, isExpanded: Binding<Bool>, content: AnyView
    ) -> AnyView
}

/// The smallest a control's touch area may be, in points, across and down.
enum TouchTarget {
    static let smallest: CGFloat = 44
}

/// A title bar with an accessory at its leading end. `bar` draws the bar around its title,
/// reports the width of the title as drawn (with whatever surrounds it, such as a mascot
/// or a paper backing) through the binding it is handed, and moves the title right by the
/// shift it is handed. The accessory is laid over the bar, so the bar keeps its size, and
/// is offered the room between the bar's leading edge and the title, less `gap`.
///
/// The title stays centred while that room is a full touch target. Where it is less, the
/// title moves right only as far as makes it one, and never past the bar's right end.
struct TitleBarWithLeadingAccessory<Bar: View>: View {
    let accessory: AnyView
    let gap: CGFloat
    @ViewBuilder let bar: (_ titleWidth: Binding<CGFloat?>, _ titleShift: CGFloat) -> Bar
    @State private var titleWidth: CGFloat?
    @State private var barWidth: CGFloat?

    struct Layout: Equatable {
        /// The width offered to the accessory.
        let room: CGFloat
        /// How far right of centre the title is drawn.
        let titleShift: CGFloat
    }

    var body: some View {
        let layout = titleWidth.flatMap { titleWidth in
            barWidth.map { Self.layout(barWidth: $0, titleWidth: titleWidth, gap: gap) }
        }
        bar($titleWidth, layout?.titleShift ?? 0)
            .reportingWidth(to: $barWidth)
            .overlay(alignment: .leading) {
                // Nothing until the title has been measured, so the accessory never
                // appears for a moment on top of it.
                if let layout {
                    accessory
                        .frame(width: layout.room, alignment: .leading)
                        .frame(maxHeight: .infinity)
                }
            }
    }

    nonisolated static func layout(barWidth: CGFloat, titleWidth: CGFloat, gap: CGFloat) -> Layout {
        let besideCentredTitle = max(0, (barWidth - titleWidth) / 2)
        let shortfall = max(0, TouchTarget.smallest + gap - besideCentredTitle)
        let titleShift = min(shortfall, besideCentredTitle)
        return Layout(room: max(0, besideCentredTitle + titleShift - gap), titleShift: titleShift)
    }
}

extension View {
    /// Reports this view's width to `width` whenever it changes, without changing layout.
    func reportingWidth(to width: Binding<CGFloat?>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width.wrappedValue = $0 }
    }

    /// Shows the view as it is when it fits the height on offer, and inside a vertical
    /// scroll view when it does not, so a short box hugs its text and a tall one scrolls.
    func scrollingWhenTaller() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView(.vertical) { self }
        }
    }
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
