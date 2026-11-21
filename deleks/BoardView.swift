import deleksCore
import SwiftUI

/// The playing field. Tap a cell to step one square toward it; tap yourself to wait.
struct BoardView: View {
    let game: Game
    let showHints: Bool
    let onTap: (Position) -> Void
    let onMove: (Direction) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { proxy in
            let cell = floor(min(
                proxy.size.width / CGFloat(game.rules.width),
                proxy.size.height / CGFloat(game.rules.height)))
            let boardSize = CGSize(
                width: cell * CGFloat(game.rules.width),
                height: cell * CGFloat(game.rules.height))

            ZStack(alignment: .topLeading) {
                theme.boardBackground(
                    columns: game.rules.width, rows: game.rules.height, cellSize: cell
                )
                .accessibilityHidden(true)

                if showHints && game.status == .playing {
                    ForEach(Direction.allCases.filter { $0 != .stay && game.isSafe($0) }, id: \.self) {
                        direction in
                        theme.safeMoveHint(cellSize: cell)
                            .position(center(of: game.player.moved(direction), cell: cell))
                            .accessibilityHidden(true)
                    }
                }

                ForEach(game.heaps.sorted { ($0.y, $0.x) < ($1.y, $1.x) }, id: \.self) { heap in
                    theme.heapGlyph(cellSize: cell)
                        .position(center(of: heap, cell: cell))
                        .transition(theme.heapTransition)
                        .accessibilityElement()
                        .accessibilityIdentifier(AccessibilityID.heap)
                        .accessibilityLabel("Scrap heap")
                        .accessibilityValue(spoken(heap))
                }

                ForEach(game.robots) { robot in
                    theme.robotGlyph(cellSize: cell)
                        .position(center(of: robot.position, cell: cell))
                        .transition(theme.robotTransition)
                        .accessibilityElement()
                        .accessibilityIdentifier(AccessibilityID.robot)
                        .accessibilityLabel("Robot")
                        .accessibilityValue(spoken(robot.position))
                }

                theme.playerGlyph(cellSize: cell, isCaught: game.status == .caught)
                    .position(center(of: game.player, cell: cell))
                    .accessibilityElement()
                    .accessibilityIdentifier(AccessibilityID.player)
                    .accessibilityLabel("You")
                    .accessibilityValue(spoken(game.player))
                    .accessibilityHint("Swipe up or down for moves")
                    .accessibilityActions {
                        ForEach(Direction.allCases.filter { game.canMove($0) }, id: \.self) { direction in
                            Button(direction.spokenName) { onMove(direction) }
                        }
                    }
            }
            .frame(width: boardSize.width, height: boardSize.height)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { tap in
                    let tapped = Position(
                        x: min(game.rules.width - 1, max(0, Int(tap.location.x / cell))),
                        y: min(game.rules.height - 1, max(0, Int(tap.location.y / cell))))
                    onTap(tapped)
                }
            )
            .overlay(theme.boardBorder().accessibilityHidden(true))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.board)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(CGFloat(game.rules.width) / CGFloat(game.rules.height), contentMode: .fit)
    }

    /// One-based column and row, as VoiceOver reads them and the UI tests parse them.
    private func spoken(_ position: Position) -> String {
        String(localized: "column \(position.x + 1), row \(position.y + 1)")
    }

    private func center(of position: Position, cell: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(position.x) + 0.5) * cell, y: (CGFloat(position.y) + 0.5) * cell)
    }
}

extension Direction {
    /// The name VoiceOver reads for a move action.
    var spokenName: LocalizedStringKey {
        switch self {
        case .north: "Move up"
        case .northEast: "Move up and right"
        case .east: "Move right"
        case .southEast: "Move down and right"
        case .south: "Move down"
        case .southWest: "Move down and left"
        case .west: "Move left"
        case .northWest: "Move up and left"
        case .stay: "Wait"
        }
    }
}
