import SwiftUI

/// The original look: one-bit ink on paper, in the style of a classic desktop. It draws
/// every action, stat and setting alike, so it takes their roles and ignores them.
struct LegacyTheme: Theme {
    var palette = OneBitPalette.classic

    var fontDesign: Font.Design { .monospaced }
    var textStyle: AnyShapeStyle { AnyShapeStyle(palette.ink) }
    var settingRowSpacing: CGFloat { 10 }

    var turnAnimation: Animation { .easeInOut(duration: 0.12) }
    var heapTransition: AnyTransition { .scale.combined(with: .opacity) }
    var robotTransition: AnyTransition { .opacity }

    func screenBackground() -> AnyView {
        AnyView(palette.paper)
    }

    func titleBar(title: AnyView) -> AnyView {
        AnyView(LegacyTitleBar(title: title, palette: palette))
    }

    func scoreboard(stats: [AnyView]) -> AnyView {
        AnyView(
            HStack {
                ForEach(stats.indices, id: \.self) { index in
                    if index > 0 {
                        Spacer()
                    }
                    stats[index]
                }
            }
            .font(.subheadline))
    }

    func scoreboardStat(role: StatRole, label: LocalizedStringKey, value: Int) -> AnyView {
        AnyView(
            VStack(spacing: 2) {
                Text(label).font(.caption2).textCase(.uppercase)
                Text("\(value)").font(.headline).monospacedDigit().contentTransition(.numericText())
            })
    }

    func boardBackground(columns: Int, rows: Int, cellSize: CGFloat) -> AnyView {
        AnyView(
            LegacyGridBackground(
                columns: columns, rows: rows, cellSize: cellSize, palette: palette))
    }

    func boardBorder() -> AnyView {
        AnyView(Rectangle().stroke(palette.ink, lineWidth: 2))
    }

    func safeMoveHint(cellSize: CGFloat) -> AnyView {
        AnyView(
            Circle()
                .stroke(palette.ink.opacity(0.45), lineWidth: 1.5)
                .frame(width: cellSize * 0.3, height: cellSize * 0.3))
    }

    func robotGlyph(cellSize: CGFloat) -> AnyView {
        AnyView(
            RobotGlyph(palette: palette)
                .frame(width: cellSize * 0.86, height: cellSize * 0.86))
    }

    func heapGlyph(cellSize: CGFloat) -> AnyView {
        AnyView(
            HeapGlyph(palette: palette)
                .frame(width: cellSize * 0.9, height: cellSize * 0.9))
    }

    func playerGlyph(cellSize: CGFloat, isCaught: Bool) -> AnyView {
        AnyView(
            PlayerGlyph(palette: palette)
                .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                .opacity(isCaught ? 0.25 : 1))
    }

    func actionButton(
        role: ActionRole, title: String, systemImage: String, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            RetroButton(title: title, systemImage: systemImage, palette: palette, action: action))
    }

    func settingToggle(
        role: SettingRole, title: LocalizedStringKey, isOn: Binding<Bool>
    ) -> AnyView {
        AnyView(
            Toggle(title, isOn: isOn)
                .toggleStyle(.button)
                .font(.caption)
                .tint(palette.ink))
    }

    func secondaryButton(
        title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            Button(title, action: action)
                .font(.caption)
                .tint(palette.ink))
    }

    /// The legacy card looks the same whether the level was cleared or lost.
    func resultCard(
        outcome: LevelOutcome, heading: AnyView, detail: AnyView, actionButton: AnyView
    ) -> AnyView {
        AnyView(
            VStack(spacing: 10) {
                heading.font(.title3.weight(.bold))
                detail.font(.subheadline)
                actionButton
            }
            .padding(20)
            .background(palette.paper)
            .overlay(Rectangle().stroke(palette.ink, lineWidth: 2))
            .background(Rectangle().fill(palette.ink).offset(x: 4, y: 4)))
    }

    func resultActionButton(
        outcome: LevelOutcome, title: LocalizedStringKey, action: @escaping () -> Void
    ) -> AnyView {
        AnyView(
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.ink, lineWidth: 2))
            }
            .buttonStyle(.plain))
    }
}

/// A striped title bar in the style of a classic desktop window.
private struct LegacyTitleBar: View {
    let title: AnyView
    let palette: OneBitPalette

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(palette.ink).frame(height: 1)
                }
            }
            title
                .font(.headline.weight(.bold))
                .padding(.horizontal, 10)
                .background(palette.paper)
        }
        .frame(height: 22)
    }
}

/// Paper with faint dots at every grid corner, like an old paint program.
private struct LegacyGridBackground: View {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let palette: OneBitPalette

    var body: some View {
        Canvas { context, _ in
            let dot = max(1, cellSize * 0.06)
            for row in 1..<rows {
                for column in 1..<columns {
                    let corner = CGRect(
                        x: CGFloat(column) * cellSize - dot / 2,
                        y: CGFloat(row) * cellSize - dot / 2,
                        width: dot, height: dot)
                    context.fill(Path(corner), with: .color(palette.ink.opacity(0.3)))
                }
            }
        }
        .background(palette.paper)
    }
}

/// A square-cornered, outlined button with a drop shadow, after old desktop buttons.
private struct RetroButton: View {
    let title: String
    let systemImage: String
    let palette: OneBitPalette
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(palette.paper)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.ink, lineWidth: 2))
            .background(
                RoundedRectangle(cornerRadius: 6).fill(palette.ink).offset(x: 2, y: 2))
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
    }
}
