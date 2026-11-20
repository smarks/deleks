// Draws the deleks app icon: a one-bit robot on a dotted paper grid.
// Usage: swift tools/icon/DrawIcon.swift <output.png>
// The App Store wants a 1024x1024 PNG with no alpha channel; this writes exactly that.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let canvas = CGFloat(side)
guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: DrawIcon.swift <output.png>\n".utf8))
    exit(2)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

let context = CGContext(
    data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Work top-down like the in-app glyphs.
context.translateBy(x: 0, y: canvas)
context.scaleBy(x: 1, y: -1)

let paper = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
let ink = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
let dotInk = CGColor(srgbRed: 0.72, green: 0.72, blue: 0.72, alpha: 1)

context.setFillColor(paper)
context.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))

// Dotted grid
let gridStep = canvas / 8
context.setFillColor(dotInk)
for row in 1..<8 {
    for column in 1..<8 {
        let dot: CGFloat = 14
        context.fill(CGRect(
            x: CGFloat(column) * gridStep - dot / 2, y: CGFloat(row) * gridStep - dot / 2,
            width: dot, height: dot))
    }
}

// The robot fills a box in the middle of the icon; shapes are fractions of that box.
let box = CGRect(x: canvas * 0.18, y: canvas * 0.14, width: canvas * 0.64, height: canvas * 0.72)
func part(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(
        x: box.minX + x * box.width, y: box.minY + y * box.height,
        width: width * box.width, height: height * box.height)
}
func fill(_ rect: CGRect, _ color: CGColor, corner: CGFloat = 0) {
    context.setFillColor(color)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    context.fillPath()
}
func fillOval(_ rect: CGRect, _ color: CGColor) {
    context.setFillColor(color)
    context.fillEllipse(in: rect)
}

// Antenna
fill(part(0.47, 0.04, 0.06, 0.16), ink)
fillOval(part(0.40, 0.0, 0.20, 0.12), ink)
// Head, visor, eyes
fill(part(0.22, 0.18, 0.56, 0.28), ink, corner: box.width * 0.05)
fill(part(0.30, 0.25, 0.40, 0.12), paper)
fill(part(0.36, 0.27, 0.09, 0.08), ink)
fill(part(0.55, 0.27, 0.09, 0.08), ink)
// Body and grille
fill(part(0.16, 0.48, 0.68, 0.30), ink)
for row in 0..<3 {
    fill(part(0.30, 0.53 + CGFloat(row) * 0.07, 0.40, 0.03), paper)
}
// Arms
fill(part(0.04, 0.52, 0.10, 0.18), ink)
fill(part(0.86, 0.52, 0.10, 0.18), ink)
// Treads and wheels
fill(part(0.10, 0.80, 0.80, 0.16), ink, corner: box.height * 0.08)
for wheel in 0..<3 {
    fillOval(part(0.20 + CGFloat(wheel) * 0.22, 0.83, 0.14, 0.10), paper)
}

let image = context.makeImage()!
let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("could not write \(outputURL.path)\n".utf8))
    exit(1)
}
