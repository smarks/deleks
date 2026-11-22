import SwiftUI

/// The modern look: rounded white cards on a soft gradient, SF Rounded type, a tiled
/// board and pieces in colour. Light and dark mode each have their own palette
/// (`ModernPalette`); the pieces are in `ModernPieces.swift`.
struct ModernTheme: Theme {
    var fontDesign: Font.Design { .rounded }
    var textStyle: AnyShapeStyle { AnyShapeStyle(ModernPalette.textPrimary.color) }
    var settingRowSpacing: CGFloat { ModernMetrics.pillRowSpacing }

    /// The motion to use right now: reduced whenever the player has Reduce Motion on.
    @MainActor private var motion: ModernMotion {
        ModernMotion(reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    @MainActor var turnAnimation: Animation { motion.turnAnimation }
    @MainActor var heapTransition: AnyTransition { motion.heapTransition }
    @MainActor var robotTransition: AnyTransition { motion.robotTransition }

    func screenBackground() -> AnyView {
        AnyView(
            LinearGradient(
                colors: [ModernPalette.screenTop.color, ModernPalette.screenBottom.color],
                startPoint: .top, endPoint: .bottom))
    }

    func titleBar(title: AnyView, accessory: AnyView) -> AnyView {
        AnyView(
            TitleBarWithLeadingAccessory(accessory: accessory, gap: ModernMetrics.accessoryGap) {
                titleWidth, titleShift in
                ModernMascotTitle(title: title)
                    .reportingWidth(to: titleWidth)
                    .offset(x: titleShift)
                    .frame(maxWidth: .infinity)
            })
    }

    func scoreboard(stats: [AnyView]) -> AnyView {
        AnyView(
            HStack(spacing: 8) {
                ForEach(stats.indices, id: \.self) { index in
                    stats[index]
                }
            }
            // As tall as the tallest stat needs, and every card that tall.
            .fixedSize(horizontal: false, vertical: true))
    }

    func scoreboardStat(role: StatRole, label: LocalizedStringKey, value: Int) -> AnyView {
        AnyView(
            VStack(spacing: 2) {
                ModernStatLabel(role: role, label: label)
                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(ModernMetrics.smallestTextScale)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modernCard(cornerRadius: ModernMetrics.smallCardCorner))
    }

    func boardBackground(columns: Int, rows: Int, cellSize: CGFloat) -> AnyView {
        AnyView(ModernBoardBackground(columns: columns, rows: rows, cellSize: cellSize))
    }

    func boardBorder() -> AnyView {
        AnyView(
            RoundedRectangle(cornerRadius: ModernMetrics.boardCorner, style: .continuous)
                .strokeBorder(ModernPalette.boardStroke.color, lineWidth: 1.5))
    }

    /// A green outline around the whole tile with a dot in the middle: a shape, so a safe
    /// square does not depend on telling green from the tile colour.
    func safeMoveHint(cellSize: CGFloat) -> AnyView {
        let tile = RoundedRectangle(
            cornerRadius: cellSize * ModernMetrics.tileCornerFraction, style: .continuous)
        let tileSide = cellSize * (1 - 2 * ModernMetrics.tileInsetFraction)
        return AnyView(
            tile
                .fill(ModernPalette.safeMove.color.opacity(ModernPalette.safeMoveFillOpacity))
                .overlay(tile.strokeBorder(ModernPalette.safeMove.color, lineWidth: 1.5))
                .overlay(
                    Circle()
                        .fill(ModernPalette.safeMove.color)
                        .frame(width: cellSize * 0.2, height: cellSize * 0.2)
                )
                .frame(width: tileSide, height: tileSide))
    }

    func robotGlyph(cellSize: CGFloat) -> AnyView {
        AnyView(ModernRobotGlyph().frame(width: cellSize * 0.86, height: cellSize * 0.86))
    }

    func heapGlyph(cellSize: CGFloat) -> AnyView {
        AnyView(ModernHeapGlyph().frame(width: cellSize * 0.9, height: cellSize * 0.9))
    }

    /// Caught, the player fades and shrinks so the robot standing on them shows through.
    func playerGlyph(cellSize: CGFloat, isCaught: Bool) -> AnyView {
        AnyView(
            ModernPlayerGlyph(isCaught: isCaught)
                .frame(width: cellSize * 0.96, height: cellSize * 0.96)
                .scaleEffect(isCaught ? 0.8 : 1)
                .opacity(isCaught ? 0.45 : 1))
    }

    func actionButton(
        role: ActionRole, title: String, systemImage: String, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            ModernActionButton(
                role: role, title: title, systemImage: systemImage, action: action))
    }

    /// A pill that fills with colour and swaps its ring for a tick when on, so on and off
    /// differ in shape as well as colour. It is the system's button-style `Toggle`, so
    /// accessibility still hears a switch.
    func settingToggle(
        role: SettingRole, title: LocalizedStringKey, isOn: Binding<Bool>
    ) -> AnyView {
        let fill = isOn.wrappedValue ? role.modernOnFill : nil
        return AnyView(
            Toggle(isOn: isOn) {
                HStack(spacing: 5) {
                    Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                    Text(title)
                }
            }
            .toggleStyle(.button)
            .buttonStyle(
                ModernPillStyle(
                    fill: fill,
                    text: isOn.wrappedValue ? ModernPalette.onColor : ModernPalette.textPrimary)
            )
            .modernControlTextSize { Text(title) })
    }

    func secondaryButton(
        title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            ModernPillButton(
                title: Text(title), systemImage: "arrow.counterclockwise", action: action))
    }

    /// Cleared: a green trophy badge, green heading and green button. Caught: the robot
    /// that got you in a red ring, with the heading and button in red running to violet.
    func resultCard(
        outcome: LevelOutcome, heading: AnyView, detail: AnyView, actionButton: AnyView
    ) -> AnyView {
        AnyView(
            VStack(spacing: 10) {
                ModernOutcomeBadge(outcome: outcome)
                heading
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(outcome.modernText.color)
                detail
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ModernPalette.textSecondary.color)
                actionButton
                    .padding(.top, 6)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
            .modernFloatingCard(border: outcome.modernGradient, lineWidth: 2)
            .transition(motion.cardTransition))
    }

    func resultActionButton(
        outcome: LevelOutcome, title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            Button(action: action) {
                ModernFilledButtonLabel(title: Text(title), fill: outcome.modernGradient)
            }
            .buttonStyle(ModernPressStyle()))
    }

    /// A pill like New game, with an information symbol; where the title bar has too little
    /// room for the pill, its title alone in the accent, shrunk to fit.
    func aboutButton(title: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            ViewThatFits(in: .horizontal) {
                ModernPillButton(
                    title: Text(verbatim: title), systemImage: "info.circle", action: action)
                Button(action: action) {
                    Text(verbatim: title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ModernPalette.accentText.color)
                        .lineLimit(1)
                        .minimumScaleFactor(ModernMetrics.smallestTextScale)
                        .frame(
                            minWidth: ModernMetrics.minimumTouchTarget,
                            minHeight: ModernMetrics.minimumTouchTarget, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ModernPressStyle())
                .modernControlTextSize { Text(verbatim: title) }
            })
    }

    func aboutScrim() -> AnyView {
        AnyView(ModernPalette.shadow.color.opacity(ModernMetrics.scrimOpacity))
    }

    /// A white rounded card, dark in dark mode, headed by the title as it is on the main
    /// screen. It arrives and leaves the way a result card does.
    func aboutBox(
        heading: AnyView, version: AnyView, sections: [AnyView], doneButton: AnyView
    ) -> AnyView {
        AnyView(
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    ModernMascotTitle(title: heading)
                    version
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ModernPalette.textSecondary.color)
                }
                .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(sections.indices, id: \.self) { index in
                        if index > 0 {
                            Divider().overlay(ModernPalette.surfaceStroke.color)
                                .accessibilityHidden(true)
                        }
                        sections[index]
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scrollingWhenTaller()
                doneButton
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .modernFloatingCard(border: ModernPalette.surfaceStroke.color, lineWidth: 1)
            .transition(motion.cardTransition))
    }

    /// Filled with the accent, like the Modern look pill when it is on.
    func aboutDoneButton(title: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                ModernFilledButtonLabel(
                    title: Text(verbatim: title), fill: ModernPalette.accentFill.color)
                    .frame(minHeight: ModernMetrics.minimumTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ModernPressStyle()))
    }

    func aboutLink(title: String, destination: URL) -> AnyView {
        AnyView(
            Link(destination: destination) {
                Text(verbatim: title)
                    .fontWeight(.semibold)
                    .foregroundStyle(ModernPalette.accentText.color)
                    .multilineTextAlignment(.leading)
            })
    }

    /// The label and its chevron in the accent, like the links: it is a control.
    func aboutDisclosure(
        label: AnyView, isExpanded: Binding<Bool>, content: AnyView
    ) -> AnyView {
        AnyView(
            DisclosureGroup(isExpanded: isExpanded) {
                content
                    .font(.caption)
                    .foregroundStyle(ModernPalette.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
            } label: {
                label.fontWeight(.semibold)
            }
            .foregroundStyle(ModernPalette.accentText.color)
            .tint(ModernPalette.accentText.color))
    }
}

// MARK: - Sizes and motion

/// Sizes more than one modern surface must agree on.
private enum ModernMetrics {
    static let boardCorner: CGFloat = 10
    /// The gap between a tile and the edge of its cell, as a fraction of the cell.
    static let tileInsetFraction: CGFloat = 0.045
    static let tileCornerFraction: CGFloat = 0.22
    static let smallCardCorner: CGFloat = 14
    static let largeCardCorner: CGFloat = 24
    static let titleMascotSize: CGFloat = 28
    /// The space between the title bar's accessory and the mascot.
    static let accessoryGap: CGFloat = 8
    /// How strongly the screen darkens behind the About box.
    static let scrimOpacity = 0.35

    /// One-line text in a fixed-width card shrinks to this share of its size, and no
    /// further, before it would have to lose letters.
    static let smallestTextScale: CGFloat = 0.5
    /// Text in the fixed-width cards and the pills stops growing here: stat names, action
    /// titles and pill titles. Any larger and the names would not fit their cards and the
    /// controls would take the board's room. Past this size the controls show their names
    /// in the large content viewer; the stat values keep growing.
    static let largestCompactTextSize = DynamicTypeSize.xxxLarge
    /// Above this text size a stat's icon no longer fits beside its name.
    static let largestTextSizeWithStatIcons = DynamicTypeSize.large

    /// The smallest target a finger can be asked to hit.
    static let minimumTouchTarget = TouchTarget.smallest
    static let pillMinimumHeight: CGFloat = 32
    /// How far above and below its outline a pill takes touches.
    static let pillTouchMargin = (minimumTouchTarget - pillMinimumHeight) / 2
    /// The gap between wrapped rows of pills: twice the touch margin, so the touch areas
    /// of two rows meet and never overlap.
    static let pillRowSpacing = 2 * pillTouchMargin
}

/// How much the modern look moves. `full` is its own motion: pieces slide with a little
/// spring, scrap pops in and robots shrink away. `reduced` is for players who have Reduce
/// Motion on: it moves exactly as the legacy look does and adds nothing to it.
enum ModernMotion: Equatable {
    case full
    case reduced

    init(reduceMotion: Bool) {
        self = reduceMotion ? .reduced : .full
    }

    private static let legacy = LegacyTheme()

    @MainActor var turnAnimation: Animation {
        switch self {
        case .full: .spring(duration: 0.28, bounce: 0.22)
        case .reduced: Self.legacy.turnAnimation
        }
    }

    @MainActor var heapTransition: AnyTransition {
        switch self {
        case .full: .scale(scale: 0.3).combined(with: .opacity)
        case .reduced: Self.legacy.heapTransition
        }
    }

    @MainActor var robotTransition: AnyTransition {
        switch self {
        case .full:
            .asymmetric(
                insertion: .opacity, removal: .scale(scale: 0.2).combined(with: .opacity))
        case .reduced: Self.legacy.robotTransition
        }
    }

    /// The card grows into place and leaves with a quick fade, or only fades. It arrives
    /// and goes when the game's state changes; it never dismisses itself.
    @MainActor var cardTransition: AnyTransition {
        switch self {
        case .full:
            .asymmetric(
                insertion: .scale(scale: 0.85).combined(with: .opacity),
                removal: .opacity.animation(.easeOut(duration: 0.12)))
        case .reduced: .opacity
        }
    }
}

// MARK: - What each role looks like

extension ActionRole {
    /// The badge behind an action's symbol.
    fileprivate var modernGradient: LinearGradient {
        let ends: (AdaptiveColor, AdaptiveColor) =
            switch self {
            case .teleport: (ModernPalette.teleportStart, ModernPalette.teleportEnd)
            case .pulse: (ModernPalette.pulseStart, ModernPalette.pulseEnd)
            case .lastStand: (ModernPalette.lastStandStart, ModernPalette.lastStandEnd)
            }
        return LinearGradient(
            colors: [ends.0.color, ends.1.color], startPoint: .top, endPoint: .bottom)
    }
}

extension SettingRole {
    /// The fill of a setting's pill while it is on. Hints take the green of the squares
    /// they mark on the board.
    fileprivate var modernOnFill: AdaptiveColor {
        switch self {
        case .safeMoveHints: ModernPalette.positiveStart
        case .modernLook: ModernPalette.accentFill
        }
    }
}

extension LevelOutcome {
    fileprivate var modernGradient: LinearGradient {
        let ends: (AdaptiveColor, AdaptiveColor) =
            switch self {
            case .cleared: (ModernPalette.positiveStart, ModernPalette.positiveEnd)
            case .caught: (ModernPalette.negativeStart, ModernPalette.negativeEnd)
            }
        return LinearGradient(
            colors: [ends.0.color, ends.1.color], startPoint: .leading, endPoint: .trailing)
    }

    fileprivate var modernText: AdaptiveColor {
        switch self {
        case .cleared: ModernPalette.positiveText
        case .caught: ModernPalette.negativeText
        }
    }
}

// MARK: - Surfaces

extension View {
    /// Holds a control's text at `largestCompactTextSize` and, for players whose text is
    /// set larger than that, shows `enlarged` in the large content viewer on a long press.
    fileprivate func modernControlTextSize(
        @ViewBuilder enlarged: () -> some View
    ) -> some View {
        dynamicTypeSize(...ModernMetrics.largestCompactTextSize)
            .accessibilityShowsLargeContentViewer(enlarged)
    }

    /// A card that floats over the game, as the result card and the About box do: the
    /// surface colour with a deep shadow, edged with `border`.
    fileprivate func modernFloatingCard(
        border: some ShapeStyle, lineWidth: CGFloat
    ) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: ModernMetrics.largeCardCorner, style: .continuous)
        return background(
            shape
                .fill(ModernPalette.surface.color)
                .shadow(color: ModernPalette.shadow.color.opacity(0.28), radius: 18, y: 8)
        )
        .overlay(shape.strokeBorder(border, lineWidth: lineWidth))
    }

    /// A raised card: the surface colour, a hairline edge and a soft shadow.
    fileprivate func modernCard(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(
            shape
                .fill(ModernPalette.surface.color)
                .shadow(color: ModernPalette.shadow.color.opacity(0.10), radius: 6, y: 3)
        )
        .overlay(shape.strokeBorder(ModernPalette.surfaceStroke.color, lineWidth: 1))
    }
}

/// The game's name in its gradient, after the robot mascot: the title of the screen and
/// of the About box.
private struct ModernMascotTitle: View {
    let title: AnyView

    var body: some View {
        HStack(spacing: 8) {
            ModernRobotGlyph()
                .frame(
                    width: ModernMetrics.titleMascotSize,
                    height: ModernMetrics.titleMascotSize)
            title
                .font(.title2.weight(.heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ModernPalette.titleStart.color, ModernPalette.titleEnd.color],
                        startPoint: .leading, endPoint: .trailing))
        }
    }
}

/// A rounded board of rounded tiles, one per cell, lifted off the screen by a shadow.
private struct ModernBoardBackground: View {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, _ in
            let inset = cellSize * ModernMetrics.tileInsetFraction
            let tile = GraphicsContext.Shading.color(ModernPalette.boardTile.color)
            for row in 0..<rows {
                for column in 0..<columns {
                    let cell = CGRect(
                        x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize,
                        width: cellSize, height: cellSize)
                    context.fill(
                        Path(
                            roundedRect: cell.insetBy(dx: inset, dy: inset),
                            cornerRadius: cellSize * ModernMetrics.tileCornerFraction,
                            style: .continuous),
                        with: tile)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ModernMetrics.boardCorner, style: .continuous)
                .fill(ModernPalette.boardBase.color)
                .shadow(color: ModernPalette.shadow.color.opacity(0.16), radius: 12, y: 6)
        )
    }
}

/// A stat's name, with its icon beside it at ordinary text sizes. The card is a quarter
/// of the screen wide whatever the text size, so the word is never cut short: above the
/// default size all four stats drop their icons together, the names stop growing at
/// `largestCompactTextSize`, and a name that still does not fit shrinks instead.
private struct ModernStatLabel: View {
    let role: StatRole
    let label: LocalizedStringKey
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if textSize <= ModernMetrics.largestTextSizeWithStatIcons {
                HStack(spacing: 4) {
                    ModernStatIcon(role: role)
                    name
                }
            }
            name
            name.minimumScaleFactor(ModernMetrics.smallestTextScale)
        }
        .dynamicTypeSize(...ModernMetrics.largestCompactTextSize)
    }

    private var name: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(ModernPalette.textSecondary.color)
            .lineLimit(1)
    }
}

/// The small picture beside a stat's label: a symbol in the stat's colour, or for the
/// robot count the robot itself. Decoration only, so accessibility never sees it.
private struct ModernStatIcon: View {
    let role: StatRole
    @ScaledMetric(relativeTo: .caption2) private var robotSize: CGFloat = 13

    var body: some View {
        Group {
            switch role {
            case .level: symbol("flag.fill", ModernPalette.statLevel)
            case .score: symbol("star.fill", ModernPalette.statScore)
            case .best: symbol("crown.fill", ModernPalette.statBest)
            case .robots: ModernRobotGlyph().frame(width: robotSize, height: robotSize)
            }
        }
        .accessibilityHidden(true)
    }

    private func symbol(_ systemName: String, _ tint: AdaptiveColor) -> some View {
        Image(systemName: systemName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint.color)
    }
}

/// A card with the action's symbol in a coloured badge above its title.
private struct ModernActionButton: View {
    let role: ActionRole
    let title: String
    let systemImage: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.body.weight(.bold))
                    .foregroundStyle(ModernPalette.onColor.color)
                    .frame(minWidth: 38, minHeight: 38)
                    .background(Circle().fill(role.modernGradient))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(ModernMetrics.smallestTextScale)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 8)
            .modernCard(cornerRadius: ModernMetrics.smallCardCorner)
            .saturation(isEnabled ? 1 : 0.2)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(ModernPressStyle())
        .modernControlTextSize { Label(title, systemImage: systemImage) }
    }
}

/// The badge at the top of a result card.
private struct ModernOutcomeBadge: View {
    let outcome: LevelOutcome
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 56

    var body: some View {
        Group {
            switch outcome {
            case .cleared:
                Image(systemName: "trophy.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ModernPalette.onColor.color)
                    .frame(width: size, height: size)
                    .background(Circle().fill(outcome.modernGradient))
            case .caught:
                ModernRobotGlyph()
                    .padding(size * 0.2)
                    .frame(width: size, height: size)
                    .background(Circle().fill(ModernPalette.negativeStart.color.opacity(0.14)))
                    .overlay(Circle().strokeBorder(outcome.modernGradient, lineWidth: 2))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Button styles

/// A lesser button of the settings row: an outlined pill with a symbol before its title.
private struct ModernPillButton: View {
    let title: Text
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage).accessibilityHidden(true)
                title
            }
        }
        .buttonStyle(ModernPillStyle(fill: nil, text: ModernPalette.accentText))
        .modernControlTextSize { title }
    }
}

/// The title of a button filled with colour: white on a capsule of `fill`.
private struct ModernFilledButtonLabel<Fill: ShapeStyle>: View {
    let title: Text
    let fill: Fill

    var body: some View {
        title
            .font(.headline)
            .foregroundStyle(ModernPalette.onColor.color)
            .padding(.horizontal, 28)
            .padding(.vertical, 11)
            .background(Capsule().fill(fill))
    }
}

/// A press dims the button. Nothing moves, so there is nothing for Reduce Motion to stop.
private struct ModernPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// The small pill of the settings row: filled when `fill` is given, otherwise a card.
private struct ModernPillStyle: ButtonStyle {
    let fill: AdaptiveColor?
    let text: AdaptiveColor

    func makeBody(configuration: Configuration) -> some View {
        ModernPill(
            label: configuration.label, isPressed: configuration.isPressed, fill: fill, text: text)
    }
}

private struct ModernPill<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let fill: AdaptiveColor?
    let text: AdaptiveColor
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        label
            .font(.caption.weight(.semibold))
            .foregroundStyle(text.color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(minHeight: ModernMetrics.pillMinimumHeight)
            .background(Capsule().fill((fill ?? ModernPalette.surface).color))
            .overlay(
                Capsule().strokeBorder(
                    (fill ?? ModernPalette.surfaceStroke).color, lineWidth: 1)
            )
            .opacity(isEnabled ? (isPressed ? 0.7 : 1) : 0.5)
            // The pill takes touches a little above and below its outline, up to a full
            // touch target, without taking any more room in the layout.
            .padding(.vertical, ModernMetrics.pillTouchMargin)
            .contentShape(Rectangle())
            .padding(.vertical, -ModernMetrics.pillTouchMargin)
    }
}
