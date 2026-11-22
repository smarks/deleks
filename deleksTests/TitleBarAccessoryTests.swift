import SwiftUI
import Testing
import UIKit

@testable import deleks

/// Where each look's title bar puts the About button, laid out for real at the widths the
/// main screen gives the bar: the content of a 320-point iPad split window, the narrowest
/// phone, and a 402-point phone. The UI tests reach only the simulator's own screen, so
/// the narrow widths are checked here.
@MainActor
@Suite("Title bar accessory")
struct TitleBarAccessoryTests {
    /// The window widths, less the main screen's 16-point padding on each side.
    nonisolated static let barWidths: [CGFloat] = [320 - 32, 375 - 32, 402 - 32]
    nonisolated static let textSizes: [DynamicTypeSize] = [.xSmall, .large, .accessibility5]

    /// The smallest touch target, in points, on each side.
    nonisolated static let smallestTouchTarget: CGFloat = 44

    @Test(arguments: AppearanceStyle.allCases, textSizes)
    func aboutSitsBesideTheTitleWithinTheBar(style: AppearanceStyle, textSize: DynamicTypeSize) throws {
        for barWidth in Self.barWidths {
            let frames = try layOut(style: style, textSize: textSize, barWidth: barWidth)
            let alone = try layOut(
                style: style, textSize: textSize, barWidth: barWidth, withAbout: false)
            let place = "\(style) at \(textSize), \(barWidth) points"
            // The button takes touches across its whole frame.
            #expect(
                frames.about.width >= Self.smallestTouchTarget,
                "About took touches only \(frames.about.width) points wide: \(place)")
            #expect(frames.about.minX >= 0, "About began left of the bar: \(place)")
            #expect(frames.about.maxX <= frames.title.minX, "About overlapped the title: \(place)")
            // Room for About never comes out of the title: it is as wide as it is in the
            // bar without About, and moving it right never takes it past the bar's end.
            #expect(
                frames.title.width == alone.title.width,
                "the title was cut to \(frames.title.width) from \(alone.title.width): \(place)")
            #expect(frames.title.maxX <= barWidth, "the title ran past the bar's right end: \(place)")
        }
    }

    private final class Frames {
        var title: CGRect?
        var about: CGRect?
    }

    /// Lays out the bar and returns the frames of its title and About button; with
    /// `withAbout` false, the bar holds nothing beside its title and the About frame is
    /// empty.
    private func layOut(
        style: AppearanceStyle, textSize: DynamicTypeSize, barWidth: CGFloat,
        withAbout: Bool = true
    ) throws -> (title: CGRect, about: CGRect) {
        let frames = Frames()
        let theme = style.theme
        let bar = theme.titleBar(
            title: AnyView(
                Text(verbatim: DisplayText.gameTitle)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                        frames.title = $0
                    }),
            accessory: withAbout
                ? AnyView(
                    theme.aboutButton(title: AboutDetails.app.content.buttonTitle) {}
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                            frames.about = $0
                        })
                : AnyView(EmptyView()))
        if !withAbout { frames.about = .zero }
        let root = bar
            .frame(width: barWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .fontDesign(theme.fontDesign)
            .environment(\.theme, theme)
            .environment(\.dynamicTypeSize, textSize)

        let scene = try #require(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: barWidth, height: 400)
        let host = UIHostingController(rootView: root)
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        // The bar measures its title first and places the accessory on the next pass.
        for _ in 0..<5 where frames.about == nil || frames.title == nil {
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        return (try #require(frames.title), try #require(frames.about))
    }
}
