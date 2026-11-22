import UIKit
import XCTest

/// Launches the real app with a fixed seed, so every run sees the same board, and holds
/// the queries every UI test class shares.
@MainActor
class GameUITestCase: XCTestCase {
    fileprivate var app: XCUIApplication!
    /// What the About box should show, read from the same resources the app bundles.
    fileprivate var about: AboutDetails!

    /// The look to launch in. Nil passes no style, which leaves the app on its saved
    /// setting and free to change it: a launch argument would pin the style for the run.
    var launchStyle: AppearanceStyle? { .legacy }

    /// The async form of `setUp`, because it is the one XCTest runs on the main actor.
    override func setUp() async throws {
        continueAfterFailure = false
        // The test bundle carries About.json and LICENSE too, and takes its version
        // numbers from the same project settings as the app.
        about = try AboutDetails.load(from: Bundle(for: GameUITestCase.self))
        launch(in: launchStyle)
    }

    /// Starts the app afresh in `style`, ending the run already going if there is one.
    /// `textSize` is a UIKit content size category name; nil leaves the simulator's own.
    fileprivate func launch(in style: AppearanceStyle?, textSize: String? = nil) {
        app = XCUIApplication()
        app.launchArguments = [
            "-\(LaunchArgument.seedKey)", "42", "-\(StorageKey.showHints)", "NO",
        ]
        if let style {
            app.launchArguments += ["-\(StorageKey.appearanceStyle)", style.rawValue]
        }
        if let textSize {
            // The key UIKit reads the preferred text size from.
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", textSize]
        }
        app.launch()
    }

    fileprivate var board: XCUIElement { app.otherElements[AccessibilityID.board] }
    fileprivate var player: XCUIElement { app.descendants(matching: .any)[AccessibilityID.player] }
    fileprivate var robots: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: AccessibilityID.robot)
    }

    fileprivate var styleToggle: XCUIElement { app.switches[AccessibilityID.styleToggle] }

    /// A switch reports "1" when on and "0" when off.
    fileprivate var modernLookIsOn: Bool { styleToggle.value as? String == "1" }

    fileprivate func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// Pictures of four surfaces every theme draws its own way, keyed by a name for
    /// failure messages. Two styles that are really drawn differ in every one of them;
    /// the toggle's own value cannot show that.
    fileprivate func themedSurfaceCaptures() -> [String: Data] {
        let surfaces = [
            "title": app.staticTexts[DisplayText.gameTitle],
            "level stat": element(AccessibilityID.level),
            "board": board,
            "teleport button": app.buttons[AccessibilityID.teleportButton],
            "about button": app.buttons[AccessibilityID.aboutButton],
        ]
        return surfaces.mapValues { $0.screenshot().pngRepresentation }
    }

    /// Names of the surfaces that look exactly alike in the two sets of captures.
    fileprivate func surfacesDrawnAlike(
        _ first: [String: Data], _ second: [String: Data]
    ) -> [String] {
        first.keys.filter { first[$0] == second[$0] }.sorted()
    }

    /// How many elements of `type` VoiceOver can land on. A button, a switch and a
    /// combined text are each spoken as one thing, so whatever a theme draws inside one
    /// (a symbol, the two halves of a stat) is not counted.
    fileprivate func countReachable(_ type: XCUIElement.ElementType) throws -> Int {
        let spokenAsOne: [XCUIElement.ElementType] = [.button, .switch, .staticText]
        func count(in snapshot: any XCUIElementSnapshot) -> Int {
            let own = snapshot.elementType == type ? 1 : 0
            if spokenAsOne.contains(snapshot.elementType) {
                return own
            }
            return own + snapshot.children.reduce(0) { $0 + count(in: $1) }
        }
        return count(in: try app.snapshot())
    }

    /// XCUITest has no public way to read an element's traits. Its snapshot carries them
    /// under `traits`, as the bit mask UIKit uses; this fails rather than guesses if a
    /// future Xcode stops answering that key.
    fileprivate func traits(of element: XCUIElement) throws -> UIAccessibilityTraits {
        let traitsKey = "traits"
        let snapshot = try XCTUnwrap(try element.snapshot() as? NSObject)
        let answersTraits = snapshot.responds(to: NSSelectorFromString(traitsKey))
        let rawTraits = try XCTUnwrap(
            answersTraits ? snapshot.value(forKey: traitsKey) as? UInt64 : nil,
            "the element snapshot no longer exposes \(traitsKey)")
        return UIAccessibilityTraits(rawValue: rawTraits)
    }

    fileprivate var aboutButton: XCUIElement { app.buttons[AccessibilityID.aboutButton] }
    fileprivate var aboutDone: XCUIElement { app.buttons[AccessibilityID.aboutDone] }

    /// Opens the About box and returns its Done button, once it is on screen.
    @discardableResult
    fileprivate func openAbout() -> XCUIElement {
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
        XCTAssertFalse(aboutDone.exists, "the About box was up before it was asked for")
        aboutButton.tap()
        XCTAssertTrue(aboutDone.waitForExistence(timeout: 5))
        return aboutDone
    }

    /// Whether all of `element` is on screen. XCUITest's `isHittable` is no help over the
    /// About box: it still lists the game behind the modal box and can report a button of
    /// the game under the point it tests.
    fileprivate func isOnScreen(_ element: XCUIElement) -> Bool {
        app.windows.firstMatch.frame.contains(element.frame)
    }

    fileprivate func value(of identifier: String) -> String {
        element(identifier).value as? String ?? ""
    }

    /// Reads "column 7, row 9" back as one-based (column, row).
    fileprivate func playerCell() throws -> (x: Int, y: Int) {
        let numbers = (player.value as? String ?? "")
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        return try XCTUnwrap(numbers.count == 2 ? (numbers[0], numbers[1]) : nil)
    }

    fileprivate func robotCells() -> [String] {
        robots.allElementsBoundByIndex.compactMap { $0.value as? String }.sorted()
    }
}

/// The whole game, driven in the legacy look. `ModernStyleUITests` runs every test here
/// again in the modern look, so both styles must keep the same accessibility surface.
class deleksUITests: GameUITestCase {
    /// Guards the two-style run itself: if the style argument stopped reaching the app,
    /// or the chosen theme stopped reaching the views, `ModernStyleUITests` would quietly
    /// test the legacy look twice. So this launches the other style as well and requires
    /// the two to be drawn differently.
    func testLaunchesInTheRequestedStyle() throws {
        let launchStyle = try XCTUnwrap(launchStyle)
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(modernLookIsOn, launchStyle == .modern)
        let drawnInLaunchStyle = themedSurfaceCaptures()

        let otherStyle = try XCTUnwrap(AppearanceStyle.allCases.first { $0 != launchStyle })
        launch(in: otherStyle)
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(modernLookIsOn, otherStyle == .modern)
        XCTAssertEqual(
            surfacesDrawnAlike(drawnInLaunchStyle, themedSurfaceCaptures()), [],
            "\(launchStyle) and \(otherStyle) drew these surfaces the same")
    }

    /// What VoiceOver is told belongs to the views, not the theme, so it is the same in
    /// every style: this runs again under `ModernStyleUITests`.
    func testEverythingIsSpokenTheSameInEveryStyle() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))

        let title = app.staticTexts[DisplayText.gameTitle]
        XCTAssertTrue(title.exists)
        XCTAssertTrue(try traits(of: title).contains(.header))
        // And the title alone: a reading that called everything a header proves nothing.
        XCTAssertFalse(try traits(of: element(AccessibilityID.level)).contains(.header))

        XCTAssertEqual(element(AccessibilityID.level).label, "Level, 1")
        XCTAssertEqual(element(AccessibilityID.score).label, "Score, 0")
        XCTAssertEqual(element(AccessibilityID.robotsLeft).label, "Robots, 8")
        // The high score has no identifier and outlives a run, so match its label's start.
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Best, "))
                .firstMatch.exists)

        XCTAssertEqual(app.buttons[AccessibilityID.teleportButton].label, "Teleport")
        XCTAssertEqual(app.buttons[AccessibilityID.pulseButton].label, "Pulse, 1 left")
        XCTAssertEqual(app.buttons[AccessibilityID.lastStandButton].label, "Last stand")
        XCTAssertEqual(app.buttons[AccessibilityID.newGameButton].label, "New game")
        XCTAssertEqual(app.switches[AccessibilityID.hintsToggle].label, "Safe-move hints")
        XCTAssertEqual(app.switches[AccessibilityID.hintsToggle].value as? String, "0")
        XCTAssertEqual(styleToggle.label, "Modern look")
        XCTAssertEqual(aboutButton.label, about.content.buttonLabel)

        XCTAssertEqual(player.label, "You")
        XCTAssertEqual(Set(robots.allElementsBoundByIndex.map(\.label)), ["Robot"])
        // Whatever a theme draws for the board's background, hints and border is hidden:
        // the only things in the board with a name or an identifier are its pieces.
        let namedInBoard = board.descendants(matching: .any)
            .matching(NSPredicate(format: "label != '' OR identifier != ''"))
        XCTAssertEqual(namedInBoard.count, robots.count + 1)

        // Nothing reaches VoiceOver that the views did not put there: the title and the
        // four stats are the only texts it can land on, and there is no picture. A theme
        // that adds a text or a picture of its own outside a button changes these counts;
        // what it draws inside a button, a switch or a stat does not.
        let textsAtLaunch = 1 + 4
        XCTAssertEqual(try countReachable(.staticText), textsAtLaunch)
        XCTAssertEqual(try countReachable(.image), 0)

        app.buttons[AccessibilityID.lastStandButton].tap()
        let cardButton = app.buttons[AccessibilityID.resultActionButton]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 15))
        XCTAssertEqual(cardButton.label, "New game")
        // Seed 42's opening board ends a last stand with the player caught, on no points.
        XCTAssertTrue(app.staticTexts["Caught!"].exists)
        XCTAssertTrue(app.staticTexts["Final score 0 · level 1"].exists)
        // The card adds its heading and its detail, and no picture.
        XCTAssertEqual(try countReachable(.staticText), textsAtLaunch + 2)
        XCTAssertEqual(try countReachable(.image), 0)
    }

    func testLaunchShowsFirstLevel() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertTrue(player.exists)
        XCTAssertEqual(value(of: AccessibilityID.level), "1")
        XCTAssertEqual(value(of: AccessibilityID.score), "0")
        XCTAssertEqual(robots.count, 8)
        XCTAssertEqual(value(of: AccessibilityID.robotsLeft), "8")
    }

    func testTappingAboveThePlayerMovesThemUp() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let before = try playerCell()
        // Tap the top-centre edge of the board: straight up from the starting cell.
        board.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.02)).tap()
        let after = try playerCell()
        XCTAssertEqual(after.x, before.x)
        XCTAssertEqual(after.y, before.y - 1)
    }

    func testTeleportMovesThePlayer() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let before = try playerCell()
        app.buttons[AccessibilityID.teleportButton].tap()
        let after = try playerCell()
        XCTAssertFalse(before == after, "teleport left the player at \(before)")
    }

    func testLastStandEndsTheLevelAndTheCardStaysUntilTapped() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.lastStandButton].tap()
        // The card's own button is the reliable handle on it: SwiftUI's container
        // element for the card comes and goes in the accessibility tree.
        let cardButton = app.buttons[AccessibilityID.resultActionButton]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons[AccessibilityID.teleportButton].isEnabled)

        // The card must not dismiss itself.
        sleep(2)
        XCTAssertTrue(cardButton.exists)
        XCTAssertTrue(cardButton.isHittable)

        // Seed 42's opening board ends a last stand with the player caught.
        XCTAssertTrue(app.staticTexts["Caught!"].exists)
        cardButton.tap()
        XCTAssertFalse(cardButton.waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons[AccessibilityID.teleportButton].isEnabled)
        XCTAssertEqual(value(of: AccessibilityID.level), "1")
        XCTAssertEqual(value(of: AccessibilityID.score), "0")
        XCTAssertEqual(robots.count, 8)
    }

    /// The box names the game, its version, who made it, where the source is and where
    /// the game comes from; the two web addresses are links, which VoiceOver says.
    func testAboutBoxShowsTheVersionCreditSourceAndHistory() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        openAbout()
        let content = about.content

        // The game's own title stays in XCUITest's tree behind the box, so look inside it.
        let heading = element(AccessibilityID.aboutBox).staticTexts[DisplayText.gameTitle]
        XCTAssertTrue(heading.exists)
        XCTAssertTrue(try traits(of: heading).contains(.header))
        XCTAssertEqual(element(AccessibilityID.aboutVersion).label, about.version)
        XCTAssertEqual(element(AccessibilityID.aboutCredit).label, content.credit)
        XCTAssertEqual(
            element(AccessibilityID.aboutLicenseSummary).label, content.licenseSummary)
        XCTAssertEqual(element(AccessibilityID.aboutHistory).label, content.history)

        // `links`, not `buttons` or `staticTexts`: each is announced as a link.
        let creditLink = app.links[AccessibilityID.aboutCreditLink]
        XCTAssertTrue(creditLink.exists)
        XCTAssertEqual(creditLink.label, content.creditLink.title)
        let sourceLink = app.links[AccessibilityID.aboutSourceLink]
        XCTAssertTrue(sourceLink.exists)
        XCTAssertEqual(sourceLink.label, content.sourceLink.title)

        // The box is modal, so VoiceOver keeps to it and skips the game behind it.
        // XCUITest still lists the game; it reports a modal container as an alert.
        XCTAssertEqual(element(AccessibilityID.aboutBox).elementType, .alert)
    }

    func testAboutLicenseOpensToShowTheLicenseText() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        openAbout()
        let licenseText = element(AccessibilityID.aboutLicenseText)
        XCTAssertFalse(licenseText.exists, "the license was open before it was asked for")

        let licenseControl = app.buttons[AccessibilityID.aboutLicense]
        XCTAssertTrue(licenseControl.exists)
        XCTAssertEqual(licenseControl.label, about.content.licenseTitle)
        licenseControl.tap()
        XCTAssertTrue(licenseText.waitForExistence(timeout: 2))
        XCTAssertEqual(licenseText.label, about.license)
    }

    /// The box never closes itself, and a tap on the game around it neither closes it nor
    /// reaches the game; only Done closes it, and the game is as it was.
    func testAboutBoxStaysUntilDoneIsTapped() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let playerBefore = try playerCell()
        let robotsBefore = robotCells()
        // Where New game is, below the box in both looks: it would deal a new board.
        let newGameSpot = app.buttons[AccessibilityID.newGameButton]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // Straight up from the player, under the box: a move, were the board to take it.
        let boardTopEdge = board.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.02))
        let done = openAbout()

        sleep(2)
        XCTAssertTrue(done.exists)
        XCTAssertTrue(isOnScreen(done))
        newGameSpot.tap()
        boardTopEdge.tap()
        XCTAssertTrue(done.exists)

        done.tap()
        XCTAssertFalse(done.waitForExistence(timeout: 1))
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(robotCells(), robotsBefore, "a tap beside the About box dealt a new game")
        let playerAfter = try playerCell()
        XCTAssertEqual(playerAfter.x, playerBefore.x)
        XCTAssertEqual(playerAfter.y, playerBefore.y, "a tap under the About box moved the player")
    }

    /// The keypad and the action letters do nothing while the box is up. Once it is
    /// closed the same key moves the player, which shows the keys did reach the app.
    func testKeysDoNothingWhileTheAboutBoxIsUp() throws {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let playerBefore = try playerCell()
        let robotsBefore = robotCells()
        let done = openAbout()

        let moveUp = "8"
        for key in [moveUp, "t", "p"] {
            app.typeKey(key, modifierFlags: [])
        }
        done.tap()
        XCTAssertFalse(done.waitForExistence(timeout: 1))
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(robotCells(), robotsBefore, "a key pressed behind the box moved the robots")
        let playerAfter = try playerCell()
        XCTAssertTrue(
            playerAfter == playerBefore, "a key pressed behind the box moved the player")
        XCTAssertTrue(
            app.buttons[AccessibilityID.pulseButton].isEnabled,
            "a key pressed behind the box spent the pulse")

        app.typeKey(moveUp, modifierFlags: [])
        let playerMoved = try playerCell()
        XCTAssertEqual(playerMoved.x, playerBefore.x)
        XCTAssertEqual(playerMoved.y, playerBefore.y - 1, "keys did not reach the game at all")
    }

    func testPulseSpendsItsCharge() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let pulse = app.buttons[AccessibilityID.pulseButton]
        XCTAssertTrue(pulse.isEnabled)
        pulse.tap()
        XCTAssertFalse(pulse.isEnabled)
    }

    func testNewGameResetsTheScoreboard() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.teleportButton].tap()
        let firstBoard = robotCells()
        app.buttons[AccessibilityID.newGameButton].tap()
        XCTAssertEqual(value(of: AccessibilityID.level), "1")
        XCTAssertEqual(value(of: AccessibilityID.score), "0")
        XCTAssertNotEqual(robotCells(), firstBoard, "New game kept the old board")
        XCTAssertEqual(robots.count, 8)
    }
}

/// Every test in `deleksUITests`, run again in the modern look.
final class ModernStyleUITests: deleksUITests {
    override var launchStyle: AppearanceStyle? { .modern }

    /// The modern pills are drawn shorter than a fingertip, so each takes touches a little
    /// beyond its outline. That touch area is the frame the pill reports, and it must be
    /// a full touch target tall; a tap at its top or bottom edge, outside the drawn
    /// outline, still reaches the pill.
    func testEveryPillOffersAFullTouchTarget() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let smallestTouchTarget: CGFloat = 44
        let newGamePill = app.buttons[AccessibilityID.newGameButton]
        let pills = [app.switches[AccessibilityID.hintsToggle], styleToggle, aboutButton, newGamePill]
        for pill in pills {
            XCTAssertGreaterThanOrEqual(pill.frame.height, smallestTouchTarget)
        }

        let justInsideTheTopAndBottomEdges: [CGFloat] = [0.03, 0.97]
        for edge in justInsideTheTopAndBottomEdges {
            let boardBefore = robotCells()
            newGamePill.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: edge)).tap()
            XCTAssertNotEqual(
                robotCells(), boardBefore,
                "a tap \(edge) of the way down New game's touch area did nothing")
        }
    }
}

/// The layout at the largest text size the scoreboard still has to fit: accessibility
/// extra large.
final class LargeTextUITests: GameUITestCase {
    private func boardWidth(in style: AppearanceStyle) -> CGFloat {
        launch(in: style, textSize: "UICTContentSizeCategoryAccessibilityXL")
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        return board.frame.width
    }

    /// Large text must not cost the modern look its board: the controls stop growing
    /// before they squeeze it smaller than the legacy look's at the same text size.
    func testTheModernBoardIsNoSmallerThanTheLegacyBoardAtLargeText() {
        let legacyWidth = boardWidth(in: .legacy)
        let defaultTextWidth: CGFloat = {
            launch(in: .legacy)
            XCTAssertTrue(board.waitForExistence(timeout: 5))
            return board.frame.width
        }()
        // The text size reached the app at all: the legacy board shrank to make room.
        XCTAssertLessThan(legacyWidth, defaultTextWidth)
        XCTAssertGreaterThanOrEqual(boardWidth(in: .modern), legacyWidth)
    }

    /// At the largest accessibility text size the About box is taller than the screen:
    /// its text scrolls, the end of the history can be scrolled into view, and Done stays
    /// on screen throughout to close it.
    func testAboutBoxScrollsAtTheLargestTextSize() {
        for style in AppearanceStyle.allCases {
            launch(in: style, textSize: "UICTContentSizeCategoryAccessibilityXXXL")
            XCTAssertTrue(board.waitForExistence(timeout: 5))
            let done = openAbout()
            let history = element(AccessibilityID.aboutHistory)
            let scrollView = app.scrollViews.firstMatch
            XCTAssertTrue(scrollView.exists, "\(style): the box did not need to scroll")
            XCTAssertTrue(isOnScreen(done), "\(style): Done was not on screen")

            // The history comes last; scroll until its last line is in view.
            func historyEndIsInView() -> Bool { history.frame.maxY <= scrollView.frame.maxY }
            XCTAssertFalse(historyEndIsInView(), "\(style): all of it fitted without scrolling")
            var swipes = 0
            while !historyEndIsInView(), swipes < 12 {
                scrollView.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(historyEndIsInView(), "\(style): the end of the history never came into view")
            XCTAssertTrue(isOnScreen(done), "\(style): scrolling took Done off screen")
            done.tap()
            XCTAssertFalse(done.waitForExistence(timeout: 1), "\(style): Done left the box up")
        }
    }

    /// The About button sits in the title bar beside the title. At the largest text size
    /// the title fills most of the bar, and About must still lie wholly on screen, clear
    /// of the title, and open the box when tapped.
    func testAboutStaysOnScreenBesideTheTitleAtTheLargestTextSize() {
        for style in AppearanceStyle.allCases {
            launch(in: style, textSize: "UICTContentSizeCategoryAccessibilityXXXL")
            XCTAssertTrue(board.waitForExistence(timeout: 5))
            XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
            let title = app.staticTexts[DisplayText.gameTitle].firstMatch
            XCTAssertTrue(isOnScreen(aboutButton), "\(style): About reached off screen")
            XCTAssertGreaterThanOrEqual(
                aboutButton.frame.width, 44, "\(style): About was narrower than a touch target")
            XCTAssertLessThanOrEqual(
                aboutButton.frame.maxX, title.frame.minX, "\(style): About overlapped the title")
            XCTAssertLessThan(
                aboutButton.frame.maxY, board.frame.minY, "\(style): About was not above the board")
            openAbout().tap()
        }
    }

    /// About is drawn smaller than a fingertip in the title bar, so it takes touches over a
    /// full touch target, which is the frame it reports. A tap near that frame's top
    /// leading corner, on the stripes or the padding outside the drawn button, opens the
    /// box. The system also accepts taps a little outside any button, so the tap alone
    /// would pass without the target; the frame's size is what checks it.
    func testAboutTakesTouchesAcrossAFullTouchTarget() {
        let smallestTouchTarget: CGFloat = 44
        let cases: [(AppearanceStyle, String?)] = [
            (.legacy, nil), (.legacy, "UICTContentSizeCategoryAccessibilityXXXL"),
            (.modern, "UICTContentSizeCategoryAccessibilityXXXL"),
        ]
        for (style, textSize) in cases {
            launch(in: style, textSize: textSize)
            XCTAssertTrue(aboutButton.waitForExistence(timeout: 5))
            let frame = aboutButton.frame
            let place = "\(style) at \(textSize ?? "the default text size")"
            // Frames come back with floating-point error far under a pixel.
            let roundingAllowance: CGFloat = 0.01
            XCTAssertGreaterThanOrEqual(frame.width, smallestTouchTarget - roundingAllowance, place)
            XCTAssertGreaterThanOrEqual(frame.height, smallestTouchTarget - roundingAllowance, place)
            // Two points in from the target's leading edge and its top edge.
            let corner = CGVector(dx: frame.minX + 2, dy: frame.minY + 2)
            app.coordinate(withNormalizedOffset: .zero).withOffset(corner).tap()
            XCTAssertTrue(
                aboutDone.waitForExistence(timeout: 5),
                "\(place): a tap at \(corner), inside About's touch target, did nothing")
            aboutDone.tap()
        }
    }

    /// At this size the modern pills wrap onto more than one row. Each takes touches
    /// beyond its outline, and the rows are spaced so that no two touch areas overlap.
    func testWrappedModernPillsDoNotShareTouchArea() {
        launch(in: .modern, textSize: "UICTContentSizeCategoryAccessibilityXL")
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let pills = [
            app.switches[AccessibilityID.hintsToggle], styleToggle,
            app.buttons[AccessibilityID.newGameButton],
        ]
        let rows = Set(pills.map { $0.frame.midY.rounded() })
        XCTAssertGreaterThan(rows.count, 1, "the pills did not wrap, so this checks nothing")

        // Frames that only meet at an edge may differ by a rounding error; shrink each by
        // less than a point so only a real overlap counts.
        let roundingAllowance: CGFloat = 0.25
        let touchAreas = pills.map {
            $0.frame.insetBy(dx: roundingAllowance, dy: roundingAllowance)
        }
        for first in touchAreas.indices {
            for second in touchAreas.indices where second > first {
                XCTAssertFalse(
                    touchAreas[first].intersects(touchAreas[second]),
                    "\(pills[first].identifier) and \(pills[second].identifier) overlap")
            }
        }
    }
}

/// The "Modern look" toggle, switching the style while the game runs.
final class AppearanceToggleUITests: GameUITestCase {
    override var launchStyle: AppearanceStyle? { nil }

    /// Starts from whichever style the last run saved, flips it and flips it back, so the
    /// test passes from either state and leaves the saved setting as it found it. The
    /// look is judged by pictures of the screen, not by the toggle's own value.
    func testStyleToggleSwitchesTheLookAndBack() {
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertTrue(styleToggle.exists)
        let wasModern = modernLookIsOn
        let drawnAtFirst = themedSurfaceCaptures()

        styleToggle.tap()
        XCTAssertEqual(modernLookIsOn, !wasModern)
        XCTAssertEqual(
            surfacesDrawnAlike(drawnAtFirst, themedSurfaceCaptures()), [],
            "flipping the toggle left these surfaces looking the same")
        XCTAssertTrue(player.exists)
        XCTAssertEqual(robots.count, 8)

        styleToggle.tap()
        XCTAssertEqual(modernLookIsOn, wasModern)
        XCTAssertEqual(
            surfacesDrawnAlike(drawnAtFirst, themedSurfaceCaptures()), drawnAtFirst.keys.sorted(),
            "flipping the toggle back did not restore every surface")
        XCTAssertTrue(player.exists)
        XCTAssertEqual(robots.count, 8)
    }
}
