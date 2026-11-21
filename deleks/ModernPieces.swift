import SwiftUI

/// Turns positions given as fractions of a glyph's box into points, so each piece is
/// drawn once and fits any cell size.
private struct GlyphBox {
    let size: CGSize

    func point(_ horizontal: CGFloat, _ vertical: CGFloat) -> CGPoint {
        CGPoint(x: horizontal * size.width, y: vertical * size.height)
    }

    func rectangle(
        left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat
    ) -> CGRect {
        CGRect(
            x: left * size.width, y: top * size.height,
            width: width * size.width, height: height * size.height)
    }

    /// A rectangle with corners rounded by a fraction of the box's width.
    func rounded(
        left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, corner: CGFloat
    ) -> Path {
        Path(
            roundedRect: rectangle(left: left, top: top, width: width, height: height),
            cornerRadius: corner * size.width, style: .continuous)
    }

    func ellipse(left: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat) -> Path {
        Path(ellipseIn: rectangle(left: left, top: top, width: width, height: height))
    }

    func polygon(_ corners: [(CGFloat, CGFloat)]) -> Path {
        var path = Path()
        path.addLines(corners.map { point($0.0, $0.1) })
        path.closeSubpath()
        return path
    }

    func verticalGradient(
        from top: AdaptiveColor, to bottom: AdaptiveColor
    ) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [top.color, bottom.color]),
            startPoint: point(0.5, 0), endPoint: point(0.5, 1))
    }
}

/// A wind-up toy robot seen from the front: a wide square head with a dark visor and two
/// lit eyes, a lamp on a short antenna, bolts for ears, a small body, stub arms and two
/// feet. Square and upright, so it reads as a robot by shape before colour.
struct ModernRobotGlyph: View {
    var body: some View {
        Canvas { context, size in
            let box = GlyphBox(size: size)
            let shell = box.verticalGradient(
                from: ModernPalette.robotBodyTop, to: ModernPalette.robotBodyBottom)
            let trim = GraphicsContext.Shading.color(ModernPalette.robotTrim.color)
            let lamp = GraphicsContext.Shading.color(ModernPalette.robotLamp.color)

            // Antenna and its lamp
            context.fill(
                Path(box.rectangle(left: 0.47, top: 0.08, width: 0.06, height: 0.13)), with: trim)
            context.fill(box.ellipse(left: 0.42, top: 0, width: 0.16, height: 0.16), with: lamp)
            // Ear bolts, arms and feet sit behind the shell
            context.fill(
                box.rounded(left: 0.04, top: 0.31, width: 0.14, height: 0.18, corner: 0.04),
                with: trim)
            context.fill(
                box.rounded(left: 0.82, top: 0.31, width: 0.14, height: 0.18, corner: 0.04),
                with: trim)
            context.fill(
                box.rounded(left: 0.11, top: 0.63, width: 0.17, height: 0.20, corner: 0.06),
                with: trim)
            context.fill(
                box.rounded(left: 0.72, top: 0.63, width: 0.17, height: 0.20, corner: 0.06),
                with: trim)
            context.fill(
                box.rounded(left: 0.27, top: 0.84, width: 0.19, height: 0.14, corner: 0.05),
                with: trim)
            context.fill(
                box.rounded(left: 0.54, top: 0.84, width: 0.19, height: 0.14, corner: 0.05),
                with: trim)
            // Body with a chest lamp
            context.fill(
                box.rounded(left: 0.25, top: 0.58, width: 0.50, height: 0.31, corner: 0.09),
                with: shell)
            context.fill(box.ellipse(left: 0.44, top: 0.69, width: 0.12, height: 0.12), with: lamp)
            // Head, visor and eyes
            context.fill(
                box.rounded(left: 0.12, top: 0.18, width: 0.76, height: 0.44, corner: 0.14),
                with: shell)
            context.fill(
                box.rounded(left: 0.21, top: 0.27, width: 0.58, height: 0.25, corner: 0.10),
                with: .color(ModernPalette.robotVisor.color))
            let eye = GraphicsContext.Shading.color(ModernPalette.robotEye.color)
            context.fill(box.ellipse(left: 0.29, top: 0.32, width: 0.15, height: 0.15), with: eye)
            context.fill(box.ellipse(left: 0.56, top: 0.32, width: 0.15, height: 0.15), with: eye)
        }
    }
}

/// What is left of robots that collided: a low, jagged pile of grey plates with a brass
/// gear on top. Wide at the base and spiky, where a robot is square and the player round.
struct ModernHeapGlyph: View {
    var body: some View {
        Canvas { context, size in
            let box = GlyphBox(size: size)
            let dark = GraphicsContext.Shading.color(ModernPalette.scrapDark.color)
            let brass = GraphicsContext.Shading.color(ModernPalette.scrapBrass.color)

            // Two plates standing up behind the mound
            context.fill(
                box.polygon([(0.18, 0.90), (0.33, 0.30), (0.52, 0.46), (0.50, 0.90)]), with: dark)
            context.fill(
                box.polygon([(0.42, 0.90), (0.61, 0.14), (0.84, 0.36), (0.90, 0.90)]),
                with: .color(ModernPalette.scrapMiddle.color))
            // The gear, perched on the first plate
            let gearCenter = box.point(0.30, 0.38)
            let gearRadius = 0.13 * size.width
            let toothRadius = 0.045 * size.width
            for tooth in 0..<8 {
                let angle = CGFloat(tooth) * .pi / 4
                let toothCenter = CGPoint(
                    x: gearCenter.x + cos(angle) * gearRadius,
                    y: gearCenter.y + sin(angle) * gearRadius)
                context.fill(Self.circle(at: toothCenter, radius: toothRadius), with: brass)
            }
            context.fill(Self.circle(at: gearCenter, radius: gearRadius), with: brass)
            context.fill(Self.circle(at: gearCenter, radius: gearRadius * 0.38), with: dark)
            // The mound in front, with two rivets
            context.fill(
                box.polygon([
                    (0.04, 0.95), (0.17, 0.68), (0.33, 0.75), (0.50, 0.58), (0.68, 0.73),
                    (0.83, 0.64), (0.96, 0.95),
                ]),
                with: .color(ModernPalette.scrapLight.color))
            context.fill(box.ellipse(left: 0.36, top: 0.81, width: 0.06, height: 0.06), with: dark)
            context.fill(box.ellipse(left: 0.60, top: 0.81, width: 0.06, height: 0.06), with: dark)
        }
    }

    private static func circle(at center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

/// The player: a small explorer in a round white helmet with a dark visor, inside a
/// ring that marks where they stand. Round where everything else on the board has
/// corners. Once caught, the ring goes and the figure turns scrap grey.
struct ModernPlayerGlyph: View {
    let isCaught: Bool

    var body: some View {
        Canvas { context, size in
            let box = GlyphBox(size: size)
            let suitTop = isCaught ? ModernPalette.scrapLight : ModernPalette.playerBodyTop
            let suitBottom = isCaught ? ModernPalette.scrapDark : ModernPalette.playerBodyBottom
            let outline = GraphicsContext.Shading.color(suitBottom.color)
            let lineWidth = max(1, 0.055 * size.width)

            if !isCaught {
                let ring = box.ellipse(left: 0.03, top: 0.03, width: 0.94, height: 0.94)
                context.fill(
                    ring,
                    with: .color(suitTop.color.opacity(ModernPalette.playerRingFillOpacity)))
                context.stroke(
                    ring, with: .color(ModernPalette.playerRing.color), lineWidth: 1.25)
            }
            // Suit: broad shoulders, narrower at the feet
            let suit = Path(
                roundedRect: box.rectangle(left: 0.27, top: 0.50, width: 0.46, height: 0.39),
                cornerRadii: RectangleCornerRadii(
                    topLeading: 0.20 * size.width, bottomLeading: 0.08 * size.width,
                    bottomTrailing: 0.08 * size.width, topTrailing: 0.20 * size.width),
                style: .continuous)
            context.fill(suit, with: box.verticalGradient(from: suitTop, to: suitBottom))
            context.fill(
                box.ellipse(left: 0.45, top: 0.64, width: 0.10, height: 0.10),
                with: .color(ModernPalette.playerHelmet.color))
            // Helmet and visor
            let helmet = box.ellipse(left: 0.29, top: 0.11, width: 0.42, height: 0.42)
            context.fill(helmet, with: .color(ModernPalette.playerHelmet.color))
            context.stroke(helmet, with: outline, lineWidth: lineWidth)
            context.fill(
                box.rounded(left: 0.36, top: 0.24, width: 0.28, height: 0.15, corner: 0.07),
                with: .color(
                    isCaught ? ModernPalette.scrapDark.color : ModernPalette.playerVisor.color))
        }
    }
}
