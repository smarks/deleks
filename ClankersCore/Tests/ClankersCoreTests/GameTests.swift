import Testing

@testable import ClankersCore

private let smallRules = GameRules(width: 9, height: 9)

private func position(_ x: Int, _ y: Int) -> Position {
    Position(x: x, y: y)
}

@Suite("Geometry")
struct GeometryTests {
    @Test func stepTowardMovesOneKingStep() {
        #expect(position(0, 0).step(toward: position(5, 3)) == position(1, 1))
        #expect(position(4, 4).step(toward: position(4, 0)) == position(4, 3))
        #expect(position(2, 2).step(toward: position(2, 2)) == position(2, 2))
    }

    @Test func directionTowardMatchesStep() {
        let origin = position(4, 4)
        for target in [position(0, 0), position(8, 4), position(4, 9), position(7, 1)] {
            let direction = Direction.toward(target, from: origin)
            #expect(origin.moved(direction) == origin.step(toward: target))
        }
        #expect(Direction.toward(origin, from: origin) == .stay)
    }

    @Test func seededGeneratorReplays() {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        let firstRun = (0..<5).map { _ in first.next() }
        let secondRun = (0..<5).map { _ in second.next() }
        #expect(firstRun == secondRun)
    }
}

@Suite("Level setup")
struct LevelSetupTests {
    @Test func firstLevelPlacesRobotsAwayFromPlayer() {
        let game = Game(seed: 42)
        #expect(game.robots.count == game.rules.robotCount(forLevel: 1))
        #expect(game.status == .playing)
        for robot in game.robots {
            #expect(robot.position.chebyshevDistance(to: game.player) > 2)
            #expect(game.isInBounds(robot.position))
        }
        #expect(Set(game.robots.map(\.position)).count == game.robots.count)
    }

    @Test func sameSeedSameBoard() {
        #expect(Game(seed: 99).robots == Game(seed: 99).robots)
    }

    @Test func robotCountGrowsAndIsCapped() {
        let rules = GameRules(width: 6, height: 6, startingRobots: 4, robotsAddedPerLevel: 4)
        #expect(rules.robotCount(forLevel: 1) == 4)
        #expect(rules.robotCount(forLevel: 2) == 8)
        #expect(rules.robotCount(forLevel: 50) == 12)
    }
}

@Suite("Turns")
struct TurnTests {
    @Test func robotsStepTowardPlayer() {
        var game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(0, 0)])
        game.move(.stay)
        #expect(game.robots.first?.position == position(1, 1))
        #expect(game.turn == 1)
    }

    @Test func collidingRobotsLeaveAHeapAndScore() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(2, 4), position(2, 3), position(0, 0)])
        let outcome = game.move(.stay)
        #expect(game.heaps == [position(3, 4)])
        #expect(outcome.robotsScrapped == 2)
        #expect(game.score == 2 * smallRules.pointsPerRobot)
        #expect(game.robots.count == 1)
    }

    @Test func robotWalkingIntoHeapIsScrapped() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(2, 4)], heaps: [position(3, 4)])
        game.move(.stay)
        #expect(game.robots.isEmpty)
        #expect(game.heaps == [position(3, 4)])
        #expect(game.status == .levelCleared)
    }

    @Test func robotReachingPlayerCatchesThem() {
        var game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(5, 5)])
        game.move(.stay)
        #expect(game.status == .caught)
    }

    @Test func playerCannotMoveIntoHeapRobotOrWall() {
        let game = Game(
            rules: smallRules, seed: 1, player: position(0, 4),
            robots: [position(1, 5)], heaps: [position(1, 4)])
        #expect(!game.canMove(.west))
        #expect(!game.canMove(.east))
        #expect(!game.canMove(.southEast))
        #expect(game.canMove(.north))
        #expect(game.canMove(.stay))
    }

    @Test func blockedMoveDoesNotSpendATurn() {
        var game = Game(rules: smallRules, seed: 1, player: position(0, 0), robots: [position(8, 8)])
        let outcome = game.move(.north)
        #expect(outcome == TurnOutcome())
        #expect(game.turn == 0)
        #expect(game.robots.first?.position == position(8, 8))
    }

    @Test func isSafeFlagsCellsNextToRobots() {
        let game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(6, 4)])
        #expect(!game.isSafe(.east))
        #expect(game.isSafe(.west))
    }

    @Test func noActionsAfterBeingCaught() {
        var game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(5, 4)])
        game.move(.stay)
        #expect(game.status == .caught)
        let turnAfterCatch = game.turn
        game.move(.north)
        game.teleport()
        game.pulse()
        game.lastStand()
        #expect(game.turn == turnAfterCatch)
    }
}

@Suite("Special actions")
struct SpecialActionTests {
    @Test func teleportLandsOnAnEmptyCell() {
        var game = Game(seed: 5)
        let start = game.player
        let occupiedBefore = Set(game.robots.map(\.position))
        game.teleport()
        #expect(game.player != start)
        #expect(!occupiedBefore.contains(game.player))
        #expect(game.isInBounds(game.player))
        #expect(game.turn == 1)
    }

    @Test func pulseScrapsAdjacentRobotsAndSpendsACharge() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(5, 5), position(3, 4), position(0, 0)])
        let outcome = game.pulse()
        #expect(outcome.robotsScrapped == 2)
        #expect(game.pulsesLeft == smallRules.startingPulses - 1)
        #expect(game.robots.map(\.position) == [position(1, 1)])
        #expect(game.status == .playing)
    }

    @Test func pulseWithNoChargesDoesNothing() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(5, 5)], pulsesLeft: 0)
        let outcome = game.pulse()
        #expect(outcome == TurnOutcome())
        #expect(game.robots.count == 1)
    }

    @Test func lastStandWinsWhenRobotsCollide() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(0, 4), position(0, 3)])
        let outcome = game.lastStand()
        #expect(game.status == .levelCleared)
        #expect(outcome.robotsScrapped == 2)
        #expect(game.score == 2 * smallRules.pointsPerRobot * smallRules.lastStandMultiplier)
    }

    @Test func lastStandEndsWhenCaught() {
        var game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(0, 0)])
        let outcome = game.lastStand()
        #expect(game.status == .caught)
        #expect(outcome.turnsTaken == 4)
    }

    @Test func holdGroundIsOneDoubledTurn() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(1, 4), position(1, 3), position(0, 0)])
        let outcome = game.holdGround()
        #expect(game.turn == 1)
        #expect(outcome.robotsScrapped == 2)
        #expect(outcome.pointsEarned == 2 * smallRules.pointsPerRobot * smallRules.lastStandMultiplier)
        #expect(game.status == .playing)
    }

    @Test func nextLevelAddsRobotsAndAPulse() {
        var game = Game(rules: smallRules, seed: 3, player: position(4, 4), robots: [])
        game.move(.stay)
        #expect(game.status == .levelCleared)
        game.nextLevel()
        #expect(game.level == 2)
        #expect(game.status == .playing)
        #expect(game.heaps.isEmpty)
        #expect(game.robots.count == smallRules.robotCount(forLevel: 2))
        #expect(game.pulsesLeft == smallRules.startingPulses + smallRules.pulsesAddedPerLevel)
    }

    @Test func nextLevelIgnoredMidLevel() {
        var game = Game(seed: 3)
        game.nextLevel()
        #expect(game.level == 1)
    }

    @Test func robotIDsStayUniqueAcrossLevels() {
        var game = Game(
            rules: smallRules, seed: 3, player: position(4, 4),
            robots: [position(0, 4), position(0, 3)])
        let firstLevelIDs = Set(game.robots.map(\.id))
        game.lastStand()
        #expect(game.status == .levelCleared)
        game.nextLevel()
        #expect(firstLevelIDs.isDisjoint(with: game.robots.map(\.id)))
        #expect(Set(game.robots.map(\.id)).count == game.robots.count)
    }

    @Test func pulseThatScrapsTheLastRobotClearsTheLevel() {
        var game = Game(rules: smallRules, seed: 1, player: position(4, 4), robots: [position(5, 4)])
        game.pulse()
        #expect(game.robots.isEmpty)
        #expect(game.status == .levelCleared)
    }

    @Test func survivorsOfAPulseCanWalkIntoAHeap() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(5, 4), position(1, 4)], heaps: [position(2, 4)])
        let outcome = game.pulse()
        #expect(outcome.robotsScrapped == 2)
        #expect(game.status == .levelCleared)
    }

    @Test func teleportWithNowhereToGoSpendsNoTurn() {
        let rules = GameRules(width: 3, height: 3)
        let ring = [
            position(0, 0), position(1, 0), position(2, 0), position(0, 1),
            position(2, 1), position(0, 2), position(1, 2), position(2, 2),
        ]
        var game = Game(rules: rules, seed: 1, player: position(1, 1), robots: ring)
        let outcome = game.teleport()
        #expect(outcome == TurnOutcome())
        #expect(game.turn == 0)
        #expect(game.player == position(1, 1))
    }
}

@Suite("Collisions")
struct CollisionTests {
    @Test func robotsMeetingOnThePlayerCatchThemAndScoreNothing() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(5, 5), position(3, 3)])
        let outcome = game.move(.stay)
        #expect(game.status == .caught)
        #expect(game.score == 0)
        #expect(outcome.robotsScrapped == 0)
        #expect(game.heaps.isEmpty)
    }

    @Test func threeRobotsMeetingMakeOneHeap() {
        var game = Game(
            rules: smallRules, seed: 1, player: position(4, 4),
            robots: [position(2, 3), position(2, 4), position(2, 5), position(8, 8)])
        let outcome = game.move(.stay)
        #expect(game.heaps == [position(3, 4)])
        #expect(outcome.robotsScrapped == 3)
        #expect(game.score == 3 * smallRules.pointsPerRobot)
        #expect(game.robots.count == 1)
    }
}

