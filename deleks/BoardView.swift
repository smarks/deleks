import deleksCore
import SwiftUI

/// The playing field. Tap a cell to step one square toward it; tap yourself to wait.
struct BoardView: View {
    let game: Game
    let showHints: Bool
    let onTap: (Position) -> Void
    let onMove: (Direction) -> Void

    var body: some View {
        GeometryReader { proxy in
            let cell = floor(min(
                proxy.size.width / CGFloat(game.rules.width),
                proxy.size.height / CGFloat(game.rules.height)))
            let boardSize = CGSize(
                width: cell * CGFloat(game.rules.width),
                height: cell * CGFloat(game.rules.height))

            ZStack(alignment: .topLeading) {
                GridBackground(columns: game.rules.width, rows: game.rules.height, cell: cell)

                if showHints && game.status == .playing {
                    ForEach(Direction.allCases.filter { $0 != .stay && game.isSafe($0) }, id: \.self) {
                        direction in
                        Circle()
                            .stroke(Palette.ink.opacity(0.45), lineWidth: 1.5)
                            .frame(width: cell * 0.3, height: cell * 0.3)
                            .position(center(of: game.player.moved(direction), cell: cell))
                    }
                }

                ForEach(game.heaps.sorted { ($0.y, $0.x) < ($1.y, $1.x) }, id: \.self) { heap in
                    HeapGlyph()
                        .frame(width: cell * 0.9, height: cell * 0.9)
                        .position(center(of: heap, cell: cell))
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityElement()
                        .accessibilityIdentifier(AccessibilityID.heap)
                        .accessibilityLabel("Scrap heap")
                        .accessibilityValue(spoken(heap))
                }

                ForEach(game.robots) { robot in
                    RobotGlyph()
                        .frame(width: cell * 0.86, height: cell * 0.86)
                        .position(center(of: robot.position, cell: cell))
                        .transition(.opacity)
                        .accessibilityElement()
                        .accessibilityIdentifier(AccessibilityID.robot)
                        .accessibilityLabel("Robot")
                        .accessibilityValue(spoken(robot.position))
                }

                PlayerGlyph()
                    .frame(width: cell * 0.8, height: cell * 0.8)
                    .opacity(game.status == .caught ? 0.25 : 1)
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
            .overlay(Rectangle().stroke(Palette.ink, lineWidth: 2))
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

/// Paper with faint dots at every grid corner, like an old paint program.
private struct GridBackground: View {
    let columns: Int
    let rows: Int
    let cell: CGFloat

    var body: some View {
        Canvas { context, _ in
            let dot = max(1, cell * 0.06)
            for row in 1..<rows {
                for column in 1..<columns {
                    let corner = CGRect(
                        x: CGFloat(column) * cell - dot / 2, y: CGFloat(row) * cell - dot / 2,
                        width: dot, height: dot)
                    context.fill(Path(corner), with: .color(Palette.ink.opacity(0.3)))
                }
            }
        }
        .background(Palette.paper)
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
