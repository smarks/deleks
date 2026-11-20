import SwiftUI

/// One-bit palette: ink on paper, swapped in dark mode.
enum Palette {
    static let ink = Color.primary
    static let paper = Color(uiColor: .systemBackground)
}

/// A boxy clanker: antenna, visor head, square body, tread base.
struct RobotGlyph: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * width, y: y * height, width: w * width, height: h * height)
            }
            let ink = GraphicsContext.Shading.color(Palette.ink)
            let paper = GraphicsContext.Shading.color(Palette.paper)

            // Antenna
            context.fill(Path(rect(0.47, 0.04, 0.06, 0.16)), with: ink)
            context.fill(Path(ellipseIn: rect(0.40, 0.0, 0.20, 0.12)), with: ink)
            // Head with a visor and two square eyes
            context.fill(Path(roundedRect: rect(0.22, 0.18, 0.56, 0.28), cornerRadius: width * 0.05), with: ink)
            context.fill(Path(rect(0.30, 0.25, 0.40, 0.12)), with: paper)
            context.fill(Path(rect(0.36, 0.27, 0.09, 0.08)), with: ink)
            context.fill(Path(rect(0.55, 0.27, 0.09, 0.08)), with: ink)
            // Body with a grille
            context.fill(Path(rect(0.16, 0.48, 0.68, 0.30)), with: ink)
            for row in 0..<3 {
                context.fill(Path(rect(0.30, 0.53 + CGFloat(row) * 0.07, 0.40, 0.03)), with: paper)
            }
            // Arms
            context.fill(Path(rect(0.04, 0.52, 0.10, 0.18)), with: ink)
            context.fill(Path(rect(0.86, 0.52, 0.10, 0.18)), with: ink)
            // Treads
            context.fill(Path(roundedRect: rect(0.10, 0.80, 0.80, 0.16), cornerRadius: height * 0.08), with: ink)
            for wheel in 0..<3 {
                context.fill(Path(ellipseIn: rect(0.20 + CGFloat(wheel) * 0.22, 0.83, 0.14, 0.10)), with: paper)
            }
        }
    }
}

/// A pile of scrap: a mound with a loose gear and a bent rod.
struct HeapGlyph: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let ink = GraphicsContext.Shading.color(Palette.ink)
            let paper = GraphicsContext.Shading.color(Palette.paper)

            var mound = Path()
            mound.move(to: CGPoint(x: 0.04 * width, y: 0.94 * height))
            mound.addLine(to: CGPoint(x: 0.20 * width, y: 0.58 * height))
            mound.addLine(to: CGPoint(x: 0.36 * width, y: 0.66 * height))
            mound.addLine(to: CGPoint(x: 0.52 * width, y: 0.40 * height))
            mound.addLine(to: CGPoint(x: 0.70 * width, y: 0.60 * height))
            mound.addLine(to: CGPoint(x: 0.82 * width, y: 0.52 * height))
            mound.addLine(to: CGPoint(x: 0.96 * width, y: 0.94 * height))
            mound.closeSubpath()
            context.fill(mound, with: ink)

            // Hatching so heaps read differently from robots at a glance
            for stripe in 0..<4 {
                let y = (0.68 + CGFloat(stripe) * 0.07) * height
                context.fill(
                    Path(CGRect(x: 0.22 * width, y: y, width: 0.56 * width, height: 0.025 * height)),
                    with: paper)
            }
            // Gear on top
            let gearCenter = CGPoint(x: 0.30 * width, y: 0.36 * height)
            let gearRadius = 0.13 * width
            for tooth in 0..<6 {
                let angle = CGFloat(tooth) * .pi / 3
                let toothCenter = CGPoint(
                    x: gearCenter.x + cos(angle) * gearRadius,
                    y: gearCenter.y + sin(angle) * gearRadius)
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: toothCenter.x - 0.04 * width, y: toothCenter.y - 0.04 * width,
                        width: 0.08 * width, height: 0.08 * width)),
                    with: ink)
            }
            context.fill(
                Path(ellipseIn: CGRect(
                    x: gearCenter.x - gearRadius, y: gearCenter.y - gearRadius,
                    width: gearRadius * 2, height: gearRadius * 2)),
                with: ink)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: gearCenter.x - gearRadius * 0.4, y: gearCenter.y - gearRadius * 0.4,
                    width: gearRadius * 0.8, height: gearRadius * 0.8)),
                with: paper)
            // Bent rod sticking out
            var rod = Path()
            rod.move(to: CGPoint(x: 0.60 * width, y: 0.46 * height))
            rod.addLine(to: CGPoint(x: 0.72 * width, y: 0.14 * height))
            rod.addLine(to: CGPoint(x: 0.88 * width, y: 0.10 * height))
            context.stroke(rod, with: ink, lineWidth: max(1.5, 0.06 * width))
        }
    }
}

/// The player: an outlined figure in a long coat, hollow so it never reads as a robot.
struct PlayerGlyph: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let ink = GraphicsContext.Shading.color(Palette.ink)
            let paper = GraphicsContext.Shading.color(Palette.paper)
            let line = max(1.5, 0.07 * width)

            let head = Path(ellipseIn: CGRect(
                x: 0.34 * width, y: 0.04 * height, width: 0.32 * width, height: 0.28 * height))
            var coat = Path()
            coat.move(to: CGPoint(x: 0.36 * width, y: 0.36 * height))
            coat.addLine(to: CGPoint(x: 0.64 * width, y: 0.36 * height))
            coat.addLine(to: CGPoint(x: 0.84 * width, y: 0.96 * height))
            coat.addLine(to: CGPoint(x: 0.16 * width, y: 0.96 * height))
            coat.closeSubpath()

            for shape in [head, coat] {
                context.fill(shape, with: paper)
                context.stroke(shape, with: ink, lineWidth: line)
            }
            // Coat seam
            var seam = Path()
            seam.move(to: CGPoint(x: 0.5 * width, y: 0.40 * height))
            seam.addLine(to: CGPoint(x: 0.5 * width, y: 0.92 * height))
            context.stroke(seam, with: ink, lineWidth: line * 0.6)
        }
    }
}
