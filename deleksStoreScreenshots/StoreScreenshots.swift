import deleksCore
import UIKit
import XCTest

/// Takes the App Store screenshots. Not part of the test suite: it has its own scheme,
/// `deleksStoreScreenshots`, and runs only when asked for (see docs/app-store/listing.md).
///
/// For each look it saves four pictures: the opening board, a game in progress with scrap
/// heaps, the card for a cleared level, and the About box. Files go to the folder named by
/// `SCREENSHOT_DIR`, which xcodebuild passes in from `TEST_RUNNER_SCREENSHOT_DIR`.
@MainActor
final class StoreScreenshots: XCTestCase {
    private var app: XCUIApplication!
    private var outputFolder: URL!

    /// The fixed seed every shot is played from, so the boards are the same on every run.
    private let seed = "42"
    /// Most turns one level may take before the run gives up on reaching a cleared card.
    private let turnLimit = 60
    /// Heaps on the board before the in-progress picture is taken.
    private let heapsForProgressShot = 2
    /// Turns the move search looks ahead, and what a scrapped robot and a cleared level
    /// are worth against one square of distance from the nearest robot.
    private let lookahead = 3
    private let scrapWeight = 100
    private let clearedWeight = 1_000
    /// How often a key the board ignored is sent again, and how long to wait for an answer.
    private let keyAttempts = 3
    private let keyAnswerSeconds: TimeInterval = 2

    override func setUp() async throws {
        continueAfterFailure = false
        let folder = try XCTUnwrap(
            ProcessInfo.processInfo.environment["SCREENSHOT_DIR"],
            "pass TEST_RUNNER_SCREENSHOT_DIR=<folder> to xcodebuild")
        outputFolder = URL(fileURLWithPath: folder, isDirectory: true)
        try FileManager.default.createDirectory(
            at: outputFolder, withIntermediateDirectories: true)
    }

    func testLegacyLook() throws {
        try captureSet(style: AppearanceStyle.legacy)
    }

    func testModernLook() throws {
        try captureSet(style: AppearanceStyle.modern)
    }

    // MARK: - One look's set

    private func captureSet(style: AppearanceStyle) throws {
        if UIDevice.current.userInterfaceIdiom == .pad { try useFullScreenApps() }
        launch(style: style)
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        try save("1-opening", style: style)

        var savedProgress = false
        for _ in 0..<turnLimit {
            if resultButton.exists { break }
            if !savedProgress && heaps.count >= heapsForProgressShot {
                try save("2-in-progress", style: style)
                savedProgress = true
            }
            try playOneTurn()
        }
        XCTAssertTrue(savedProgress, "no heaps formed in \(turnLimit) turns")
        XCTAssertTrue(resultButton.waitForExistence(timeout: 15), "the level never ended")
        XCTAssertFalse(
            app.staticTexts["Caught!"].exists,
            "seed \(seed) gets the player caught; choose another seed")
        try save("3-cleared", style: style)

        resultButton.tap()
        app.buttons[AccessibilityID.aboutButton].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.aboutDone].waitForExistence(timeout: 5))
        try save("4-about", style: style)
    }

    // MARK: - Playing

    /// Plays the move that scraps the most robots over the next few turns without being
    /// caught, preferring squares farther from the robots; with no safe line of play,
    /// pulses if a charge is left and teleports if not.
    private func playOneTurn() throws {
        let game = try gameOnScreen()
        var best: (direction: Direction, score: Int)?
        for direction in Direction.allCases where game.canMove(direction) {
            var next = game
            let outcome = next.move(direction)
            guard let rest = score(of: next, lookahead: lookahead - 1) else { continue }
            let total = outcome.robotsScrapped * scrapWeight + rest
            if best == nil || total > best!.score { best = (direction, total) }
        }
        if let best {
            try press(best.direction)
            return
        }
        let pulse = app.buttons[AccessibilityID.pulseButton]
        if pulse.isEnabled {
            pulse.tap()
        } else {
            app.buttons[AccessibilityID.teleportButton].tap()
        }
    }

    /// The best score reachable from `game` in `lookahead` more turns, or nil if every
    /// line of play gets the player caught.
    private func score(of game: Game, lookahead: Int) -> Int? {
        switch game.status {
        case .caught: return nil
        case .levelCleared: return clearedWeight
        case .playing: break
        }
        if lookahead == 0 {
            return game.robots.map { $0.position.chebyshevDistance(to: game.player) }.min()
        }
        var best: Int?
        for direction in Direction.allCases where game.canMove(direction) {
            var next = game
            let outcome = next.move(direction)
            guard let rest = score(of: next, lookahead: lookahead - 1) else { continue }
            let total = outcome.robotsScrapped * scrapWeight + rest
            if best == nil || total > best! { best = total }
        }
        return best
    }

    /// The board on screen as an engine game, with the app's default rules. The seed only
    /// drives teleports, which the search never plays.
    private func gameOnScreen() throws -> Game {
        Game(
            seed: 0,
            player: try position(of: player),
            robots: try robots.allElementsBoundByIndex.map { try position(of: $0) },
            heaps: Set(try heaps.allElementsBoundByIndex.map { try position(of: $0) }))
    }

    /// Types the keypad key for `direction` and waits for the board to answer. A freshly
    /// installed app can miss its first keys while it takes keyboard focus, so a key the
    /// board ignores is sent again. Every accepted move changes the board: robots always
    /// step, and the search never picks a move that ends the game in place.
    private func press(_ direction: Direction) throws {
        let key = try XCTUnwrap(Keypad.directions.first { $0.value == direction }?.key)
        let before = boardSnapshot()
        for _ in 0..<keyAttempts {
            app.typeKey(String(key), modifierFlags: [])
            let answered = expectation(
                for: NSPredicate { [unowned self] _, _ in self.boardSnapshot() != before },
                evaluatedWith: nil)
            if XCTWaiter().wait(for: [answered], timeout: keyAnswerSeconds) == .completed {
                return
            }
        }
        XCTFail("the board ignored key \(key) \(keyAttempts) times")
    }

    /// What every piece says about its square, so a turn that moved anything shows as a
    /// change.
    private func boardSnapshot() -> [String?] {
        ([player] + robots.allElementsBoundByIndex).map { $0.value as? String }
    }

    // MARK: - Helpers

    /// Store shots of an iPad show the app full screen, so this sets the simulator's
    /// Multitasking setting to Full Screen Apps. A windowed app shows a resize handle and
    /// its own name in the status bar.
    private func useFullScreenApps() throws {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let multitasking = settings.staticTexts["Multitasking & Gestures"]
        XCTAssertTrue(multitasking.waitForExistence(timeout: 10), "no Multitasking setting")
        multitasking.tap()
        let fullScreen = settings.staticTexts["Full Screen Apps"]
        XCTAssertTrue(fullScreen.waitForExistence(timeout: 10), "no Full Screen Apps option")
        fullScreen.tap()
        settings.terminate()
    }

    private func launch(style: AppearanceStyle) {
        app = XCUIApplication()
        app.launchArguments = [
            "-\(LaunchArgument.seedKey)", seed,
            "-\(StorageKey.showHints)", "YES",
            "-\(StorageKey.appearanceStyle)", style.rawValue,
            // Each look's opening shows a best score of 0, not the other run's.
            "-\(StorageKey.highScore)", "0",
        ]
        app.launch()
    }

    private var board: XCUIElement { app.otherElements[AccessibilityID.board] }
    private var player: XCUIElement { app.descendants(matching: .any)[AccessibilityID.player] }
    private var robots: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: AccessibilityID.robot)
    }
    private var heaps: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: AccessibilityID.heap)
    }
    private var resultButton: XCUIElement { app.buttons[AccessibilityID.resultActionButton] }

    /// Reads "column 7, row 9", which is one-based, back as the engine's zero-based square.
    private func position(of element: XCUIElement) throws -> Position {
        let spoken = try XCTUnwrap(element.value as? String, "\(element) has no value")
        let numbers = spoken.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        let pair = try XCTUnwrap(numbers.count == 2 ? numbers : nil, "unreadable: \(spoken)")
        return Position(x: pair[0] - 1, y: pair[1] - 1)
    }

    private func save(_ name: String, style: AppearanceStyle) throws {
        let file = outputFolder.appendingPathComponent("\(style.rawValue)-\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }
}
