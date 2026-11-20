import XCTest

/// Drives the real app with a fixed seed so every run sees the same board.
final class ClankersUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-\(LaunchArgument.seedKey)", "42", "-\(StorageKey.showHints)", "NO",
        ]
        app.launch()
    }

    private var board: XCUIElement { app.otherElements[AccessibilityID.board] }
    private var player: XCUIElement { app.descendants(matching: .any)[AccessibilityID.player] }
    private var robots: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: AccessibilityID.robot)
    }

    private func value(of identifier: String) -> String {
        app.descendants(matching: .any)[identifier].value as? String ?? ""
    }

    /// Reads "column 7, row 9" back as one-based (column, row).
    private func playerCell() throws -> (x: Int, y: Int) {
        let numbers = (player.value as? String ?? "")
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        return try XCTUnwrap(numbers.count == 2 ? (numbers[0], numbers[1]) : nil)
    }

    private func robotCells() -> [String] {
        robots.allElementsBoundByIndex.compactMap { $0.value as? String }.sorted()
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
