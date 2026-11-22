import deleksCore
import SwiftUI

struct ContentView: View {
    let model: GameModel
    @AppStorage(StorageKey.showHints) private var showHints = false
    @AppStorage(StorageKey.appearanceStyle) private var style: AppearanceStyle = .initial
    @FocusState private var boardFocused: Bool
    @State private var showsAbout = false

    var body: some View {
        let theme = style.theme
        VStack(spacing: 12) {
            theme.titleBar(
                title: AnyView(
                    Text(verbatim: DisplayText.gameTitle).accessibilityAddTraits(.isHeader)),
                accessory: AnyView(aboutButton))
            Scoreboard(game: model.game, highScore: model.highScore)

            BoardView(game: model.game, showHints: showHints, onTap: model.tap(cell:), onMove: model.move)
            .id(model.gameGeneration)
            .overlay { resultCard }
            .animation(theme.turnAnimation, value: model.game.turn)
            .animation(theme.turnAnimation, value: model.game.level)

            // Never squeezed below its own height: at large text sizes the board gives
            // up the room instead, so a button's title stays inside its border.
            Controls(model: model, showHints: $showHints, modernLook: $style.isModern)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        // Fill the window, so the background reaches every edge of the screen and not
        // only the height of the content.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.screenBackground().ignoresSafeArea().accessibilityHidden(true))
        .overlay {
            if showsAbout {
                // Takes every touch, so the game cannot be played under the box.
                theme.aboutScrim()
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
        }
        .overlay {
            if showsAbout {
                AboutBox(details: .app) { showsAbout = false }
            }
        }
        .animation(theme.turnAnimation, value: showsAbout)
        .fontDesign(theme.fontDesign)
        .foregroundStyle(theme.textStyle)
        .environment(\.theme, theme)
        .sensoryFeedback(.impact(weight: .medium), trigger: model.scrapEvents)
        .sensoryFeedback(.error, trigger: model.game.status == .caught) { _, caught in caught }
        .focusable()
        .focused($boardFocused)
        .focusEffectDisabled()
        .onKeyPress(action: handleKey)
        .onAppear { boardFocused = true }
    }

    /// In the title bar, beside the title: a place the game's own layout never needs, so
    /// the button cannot take room from the board or the settings at any size.
    private var aboutButton: some View {
        let content = AboutDetails.app.content
        return style.theme.aboutButton(title: content.buttonTitle) { showsAbout = true }
            .accessibilityLabel(Text(verbatim: content.buttonLabel))
            .accessibilityIdentifier(AccessibilityID.aboutButton)
    }

    @ViewBuilder
    private var resultCard: some View {
        switch model.game.status {
        case .playing:
            EmptyView()
        case .levelCleared:
            ResultCard(
                outcome: .cleared,
                heading: "Level \(model.game.level) cleared",
                detail: "Score \(model.game.score)",
                actionTitle: "Next level"
            ) { model.nextLevel() }
        case .caught:
            ResultCard(
                outcome: .caught,
                heading: "Caught!",
                detail: "Final score \(model.game.score) · level \(model.game.level)",
                actionTitle: "New game"
            ) { model.newGame() }
        }
    }

    /// Numeric keypad layout (7 8 9 / 4 5 6 / 1 2 3) for hardware keyboards,
    /// plus T, P and L for the three actions.
    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        guard !showsAbout else { return .ignored }
        guard let key = press.characters.lowercased().first else { return .ignored }
        if let direction = Keypad.directions[key] {
            model.move(direction)
            return .handled
        }
        switch key {
        case "t": model.teleport()
        case "p": model.pulse()
        case "l": model.lastStand()
        default: return .ignored
        }
        return .handled
    }
}

private struct Scoreboard: View {
    let game: Game
    let highScore: Int
    @Environment(\.theme) private var theme

    var body: some View {
        theme.scoreboard(stats: [
            stat(.level, "Level", game.level, id: AccessibilityID.level),
            stat(.score, "Score", game.score, id: AccessibilityID.score),
            stat(.best, "Best", highScore, id: nil),
            stat(.robots, "Robots", game.robots.count, id: AccessibilityID.robotsLeft),
        ])
    }

    /// Spoken as "Level, 1" whatever the theme draws for the stat.
    private func stat(
        _ role: StatRole, _ label: LocalizedStringKey, _ value: Int, id: String?
    ) -> AnyView {
        AnyView(
            theme.scoreboardStat(role: role, label: label, value: value)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Text(label)), \(value)")
                .accessibilityIdentifier(id ?? "")
                .accessibilityValue("\(value)"))
    }
}

private struct Controls: View {
    let model: GameModel
    @Binding var showHints: Bool
    @Binding var modernLook: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                actionButton(
                    .teleport, "Teleport", systemImage: "sparkles",
                    identifier: AccessibilityID.teleportButton
                ) {
                    model.teleport()
                }

                actionButton(
                    .pulse, "Pulse ×\(model.game.pulsesLeft)",
                    spokenLabel: Text("Pulse, \(model.game.pulsesLeft) left"),
                    systemImage: "dot.radiowaves.left.and.right",
                    identifier: AccessibilityID.pulseButton
                ) {
                    model.pulse()
                }
                .disabled(model.game.pulsesLeft == 0)

                actionButton(
                    .lastStand, "Last stand", systemImage: "hand.raised.fill",
                    identifier: AccessibilityID.lastStandButton
                ) {
                    model.lastStand()
                }
            }
            .disabled(!model.acceptsInput)

            // One row where it fits. Larger text sizes and narrower screens drop
            // "New game" to a second row, and at the largest sizes stack all three.
            ViewThatFits(in: .horizontal) {
                HStack {
                    hintsToggle
                    styleToggle
                    Spacer()
                    newGameButton
                }
                VStack(spacing: theme.settingRowSpacing) {
                    HStack {
                        hintsToggle
                        styleToggle
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        newGameButton
                    }
                }
                VStack(spacing: theme.settingRowSpacing) {
                    hintsToggle
                    styleToggle
                    newGameButton
                }
            }
        }
    }

    private var hintsToggle: some View {
        settingToggle(
            .safeMoveHints, "Safe-move hints", isOn: $showHints,
            identifier: AccessibilityID.hintsToggle)
    }

    private var styleToggle: some View {
        settingToggle(
            .modernLook, "Modern look", isOn: $modernLook,
            identifier: AccessibilityID.styleToggle)
    }

    private var newGameButton: some View {
        let title: LocalizedStringKey = "New game"
        return theme.secondaryButton(title: title) { model.newGame() }
            .disabled(model.isRunningLastStand)
            .accessibilityLabel(title)
            .accessibilityIdentifier(AccessibilityID.newGameButton)
    }

    /// An action button that is spoken as its title unless `spokenLabel` says otherwise.
    private func actionButton(
        _ role: ActionRole, _ title: String, spokenLabel: Text? = nil, systemImage: String,
        identifier: String, action: @escaping () -> Void
    ) -> some View {
        theme.actionButton(role: role, title: title, systemImage: systemImage, action: action)
            .accessibilityLabel(spokenLabel ?? Text(title))
            .accessibilityIdentifier(identifier)
    }

    private func settingToggle(
        _ role: SettingRole, _ title: LocalizedStringKey, isOn: Binding<Bool>, identifier: String
    ) -> some View {
        theme.settingToggle(role: role, title: title, isOn: isOn)
            .accessibilityLabel(title)
            .accessibilityIdentifier(identifier)
    }
}

/// Stays on the board until the player taps its button; never auto-dismisses.
private struct ResultCard: View {
    let outcome: LevelOutcome
    let heading: LocalizedStringKey
    let detail: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        theme.resultCard(
            outcome: outcome,
            heading: AnyView(Text(heading)),
            detail: AnyView(Text(detail)),
            actionButton: AnyView(
                theme.resultActionButton(outcome: outcome, title: actionTitle, action: action)
                    .accessibilityLabel(actionTitle)
                    .accessibilityIdentifier(AccessibilityID.resultActionButton))
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.resultCard)
    }
}
