import deleksCore
import SwiftUI

struct ContentView: View {
    let model: GameModel
    @AppStorage(StorageKey.showHints) private var showHints = false
    @FocusState private var boardFocused: Bool

    private let turnAnimation = Animation.easeInOut(duration: 0.12)

    var body: some View {
        VStack(spacing: 12) {
            TitleBar(title: "deleks")
            Scoreboard(game: model.game, highScore: model.highScore)

            BoardView(game: model.game, showHints: showHints, onTap: model.tap(cell:), onMove: model.move)
            .id(model.gameGeneration)
            .overlay { resultCard }
            .animation(turnAnimation, value: model.game.turn)
            .animation(turnAnimation, value: model.game.level)

            Controls(model: model, showHints: $showHints)
        }
        .padding(16)
        .background(Palette.paper.ignoresSafeArea())
        .fontDesign(.monospaced)
        .foregroundStyle(Palette.ink)
        .sensoryFeedback(.impact(weight: .medium), trigger: model.scrapEvents)
        .sensoryFeedback(.error, trigger: model.game.status == .caught) { _, caught in caught }
        .focusable()
        .focused($boardFocused)
        .focusEffectDisabled()
        .onKeyPress(action: handleKey)
        .onAppear { boardFocused = true }
    }

    @ViewBuilder
    private var resultCard: some View {
        switch model.game.status {
        case .playing:
            EmptyView()
        case .levelCleared:
            ResultCard(
                heading: "Level \(model.game.level) cleared",
                detail: "Score \(model.game.score)",
                actionTitle: "Next level"
            ) { model.nextLevel() }
        case .caught:
            ResultCard(
                heading: "Caught!",
                detail: "Final score \(model.game.score) · level \(model.game.level)",
                actionTitle: "New game"
            ) { model.newGame() }
        }
    }

    /// Numeric keypad layout (7 8 9 / 4 5 6 / 1 2 3) for hardware keyboards,
    /// plus T, P and L for the three actions.
    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        let keypad: [Character: Direction] = [
            "7": .northWest, "8": .north, "9": .northEast,
            "4": .west, "5": .stay, "6": .east,
            "1": .southWest, "2": .south, "3": .southEast,
        ]
        guard let key = press.characters.lowercased().first else { return .ignored }
        if let direction = keypad[key] {
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

/// A striped title bar in the style of a classic desktop window.
private struct TitleBar: View {
    let title: String

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Palette.ink).frame(height: 1)
                }
            }
            Text(title)
                .font(.headline.weight(.bold))
                .padding(.horizontal, 10)
                .background(Palette.paper)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(height: 22)
    }
}

private struct Scoreboard: View {
    let game: Game
    let highScore: Int

    var body: some View {
        HStack {
            stat("Level", game.level, id: AccessibilityID.level)
            Spacer()
            stat("Score", game.score, id: AccessibilityID.score)
            Spacer()
            stat("Best", highScore, id: nil)
            Spacer()
            stat("Robots", game.robots.count, id: AccessibilityID.robotsLeft)
        }
        .font(.subheadline)
    }

    private func stat(_ label: LocalizedStringKey, _ value: Int, id: String?) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).textCase(.uppercase)
            Text("\(value)").font(.headline).monospacedDigit().contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id ?? "")
        .accessibilityValue("\(value)")
    }
}

private struct Controls: View {
    let model: GameModel
    @Binding var showHints: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                RetroButton(title: "Teleport", systemImage: "sparkles") {
                    model.teleport()
                }
                .accessibilityIdentifier(AccessibilityID.teleportButton)

                RetroButton(title: "Pulse ×\(model.game.pulsesLeft)", systemImage: "dot.radiowaves.left.and.right") {
                    model.pulse()
                }
                .disabled(model.game.pulsesLeft == 0)
                .accessibilityLabel("Pulse, \(model.game.pulsesLeft) left")
                .accessibilityIdentifier(AccessibilityID.pulseButton)

                RetroButton(title: "Last stand", systemImage: "hand.raised.fill") {
                    model.lastStand()
                }
                .accessibilityIdentifier(AccessibilityID.lastStandButton)
            }
            .disabled(!model.acceptsInput)

            HStack {
                Toggle("Safe-move hints", isOn: $showHints)
                    .toggleStyle(.button)
                    .font(.caption)
                    .accessibilityIdentifier(AccessibilityID.hintsToggle)
                Spacer()
                Button("New game") { model.newGame() }
                    .font(.caption)
                    .disabled(model.isRunningLastStand)
                    .accessibilityIdentifier(AccessibilityID.newGameButton)
            }
            .tint(Palette.ink)
        }
    }
}

/// A square-cornered, outlined button with a drop shadow, after old desktop buttons.
private struct RetroButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Palette.paper)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.ink, lineWidth: 2))
            .background(
                RoundedRectangle(cornerRadius: 6).fill(Palette.ink).offset(x: 2, y: 2))
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
    }
}

/// Stays on the board until the player taps its button; never auto-dismisses.
private struct ResultCard: View {
    let heading: LocalizedStringKey
    let detail: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(heading).font(.title3.weight(.bold))
            Text(detail).font(.subheadline)
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.resultActionButton)
        }
        .padding(20)
        .background(Palette.paper)
        .overlay(Rectangle().stroke(Palette.ink, lineWidth: 2))
        .background(Rectangle().fill(Palette.ink).offset(x: 4, y: 4))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.resultCard)
    }
}
