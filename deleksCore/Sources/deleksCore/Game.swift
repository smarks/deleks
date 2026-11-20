/// Tunable numbers for a game. Defaults suit a portrait phone screen.
public struct GameRules: Sendable, Equatable {
    public var width: Int
    public var height: Int
    public var startingRobots: Int
    public var robotsAddedPerLevel: Int
    public var startingPulses: Int
    public var pulsesAddedPerLevel: Int
    public var pointsPerRobot: Int
    /// Robots scrapped during a last stand score this many times the usual points.
    public var lastStandMultiplier: Int

    public init(
        width: Int = 12,
        height: Int = 16,
        startingRobots: Int = 8,
        robotsAddedPerLevel: Int = 4,
        startingPulses: Int = 1,
        pulsesAddedPerLevel: Int = 1,
        pointsPerRobot: Int = 10,
        lastStandMultiplier: Int = 2
    ) {
        self.width = width
        self.height = height
        self.startingRobots = startingRobots
        self.robotsAddedPerLevel = robotsAddedPerLevel
        self.startingPulses = startingPulses
        self.pulsesAddedPerLevel = pulsesAddedPerLevel
        self.pointsPerRobot = pointsPerRobot
        self.lastStandMultiplier = lastStandMultiplier
    }

    /// Robots placed on `level`, capped so the board always has room to breathe.
    public func robotCount(forLevel level: Int) -> Int {
        let requested = startingRobots + robotsAddedPerLevel * (level - 1)
        return min(requested, width * height / 3)
    }
}

public struct Robot: Identifiable, Hashable, Sendable {
    public let id: Int
    public var position: Position

    public init(id: Int, position: Position) {
        self.id = id
        self.position = position
    }
}

public enum GameStatus: Equatable, Sendable {
    case playing
    case levelCleared
    case caught
}

/// What a single turn did, so the interface can react (sounds, haptics, messages).
public struct TurnOutcome: Equatable, Sendable {
    public var robotsScrapped: Int = 0
    public var pointsEarned: Int = 0
    public var turnsTaken: Int = 0

    public init(robotsScrapped: Int = 0, pointsEarned: Int = 0, turnsTaken: Int = 0) {
        self.robotsScrapped = robotsScrapped
        self.pointsEarned = pointsEarned
        self.turnsTaken = turnsTaken
    }
}

/// The whole game: board, pieces, score and the turn rules. Pure value type, no UI.
public struct Game: Sendable {
    public let rules: GameRules
    public private(set) var level: Int = 1
    public private(set) var score: Int = 0
    public private(set) var turn: Int = 0
    public private(set) var pulsesLeft: Int
    public private(set) var status: GameStatus = .playing
    public private(set) var player: Position
    public private(set) var robots: [Robot] = []
    public private(set) var heaps: Set<Position> = []

    private var generator: SeededGenerator
    private var nextRobotID = 0

    public init(rules: GameRules = GameRules(), seed: UInt64) {
        precondition(rules.width >= 3 && rules.height >= 3, "board must be at least 3x3")
        self.rules = rules
        generator = SeededGenerator(seed: seed)
        pulsesLeft = rules.startingPulses
        player = Position(x: rules.width / 2, y: rules.height / 2)
        setUpLevel()
    }

    /// Builds a game in an exact position. For tests and replays.
    public init(
        rules: GameRules = GameRules(),
        seed: UInt64,
        player: Position,
        robots: [Position],
        heaps: Set<Position> = [],
        level: Int = 1,
        pulsesLeft: Int? = nil
    ) {
        precondition(rules.width >= 3 && rules.height >= 3, "board must be at least 3x3")
        let occupied = robots + Array(heaps) + [player]
        precondition(occupied.allSatisfy { position in
            (0..<rules.width).contains(position.x) && (0..<rules.height).contains(position.y)
        }, "every piece must be on the board")
        precondition(Set(occupied).count == occupied.count, "no two pieces may share a cell")
        self.rules = rules
        generator = SeededGenerator(seed: seed)
        self.level = level
        self.pulsesLeft = pulsesLeft ?? rules.startingPulses
        self.player = player
        self.heaps = heaps
        self.robots = robots.enumerated().map { Robot(id: $0.offset, position: $0.element) }
        nextRobotID = robots.count
    }

    // MARK: - Queries

    public func isInBounds(_ position: Position) -> Bool {
        (0..<rules.width).contains(position.x) && (0..<rules.height).contains(position.y)
    }

    public func hasRobot(at position: Position) -> Bool {
        robots.contains { $0.position == position }
    }

    /// Whether the player may step this way: on the board, not into a heap or a robot.
    public func canMove(_ direction: Direction) -> Bool {
        guard status == .playing else { return false }
        if direction == .stay { return true }
        let destination = player.moved(direction)
        return isInBounds(destination) && !heaps.contains(destination)
            && !hasRobot(at: destination)
    }

    /// Whether stepping this way leaves the player out of every robot's reach next turn.
    public func isSafe(_ direction: Direction) -> Bool {
        guard canMove(direction) else { return false }
        let destination = player.moved(direction)
        return !robots.contains { $0.position.chebyshevDistance(to: destination) <= 1 }
    }

    // MARK: - Actions

    /// Steps the player one cell (or stands still), then the robots advance.
    @discardableResult
    public mutating func move(_ direction: Direction) -> TurnOutcome {
        guard canMove(direction) else { return TurnOutcome() }
        player = player.moved(direction)
        return advanceRobots(multiplier: 1)
    }

    /// Jumps to a random empty cell. It may land next to a robot; that is the gamble.
    @discardableResult
    public mutating func teleport() -> TurnOutcome {
        guard status == .playing else { return TurnOutcome() }
        let occupied = heaps.union(robots.map(\.position)).union([player])
        let open = allCells.filter { !occupied.contains($0) }
        guard let destination = open.randomElement(using: &generator) else { return TurnOutcome() }
        player = destination
        return advanceRobots(multiplier: 1)
    }

    /// Spends a pulse to scrap every robot touching the player, then the rest advance.
    @discardableResult
    public mutating func pulse() -> TurnOutcome {
        guard status == .playing, pulsesLeft > 0 else { return TurnOutcome() }
        pulsesLeft -= 1
        let adjacent = robots.filter { $0.position.chebyshevDistance(to: player) <= 1 }
        robots.removeAll { $0.position.chebyshevDistance(to: player) <= 1 }
        let pulsePoints = adjacent.count * rules.pointsPerRobot
        score += pulsePoints
        var outcome = advanceRobots(multiplier: 1)
        outcome.robotsScrapped += adjacent.count
        outcome.pointsEarned += pulsePoints
        return outcome
    }

    /// One turn of a last stand: the player holds still and robots scrapped score extra.
    /// The interface calls this repeatedly to animate a last stand turn by turn.
    @discardableResult
    public mutating func holdGround() -> TurnOutcome {
        guard status == .playing else { return TurnOutcome() }
        return advanceRobots(multiplier: rules.lastStandMultiplier)
    }

    /// Stands still until every robot is scrapped or the player is caught.
    /// Robots scrapped this way score extra.
    @discardableResult
    public mutating func lastStand() -> TurnOutcome {
        var total = TurnOutcome()
        while status == .playing {
            let outcome = holdGround()
            total.robotsScrapped += outcome.robotsScrapped
            total.pointsEarned += outcome.pointsEarned
            total.turnsTaken += outcome.turnsTaken
        }
        return total
    }

    /// Moves on to the next, harder level after a clear.
    public mutating func nextLevel() {
        guard status == .levelCleared else { return }
        level += 1
        pulsesLeft += rules.pulsesAddedPerLevel
        setUpLevel()
    }

    // MARK: - Turn engine

    private var allCells: [Position] {
        (0..<rules.height).flatMap { row in
            (0..<rules.width).map { column in Position(x: column, y: row) }
        }
    }

    /// Every robot steps toward the player at once. Robots that meet, or walk into a
    /// heap, become scrap; a robot that reaches the player catches them.
    private mutating func advanceRobots(multiplier: Int) -> TurnOutcome {
        turn += 1
        var arrivals: [Position: [Robot]] = [:]
        for robot in robots {
            var moved = robot
            moved.position = robot.position.step(toward: player)
            arrivals[moved.position, default: []].append(moved)
        }

        var survivors: [Robot] = []
        var scrapped = 0
        for (position, arriving) in arrivals {
            if position == player {
                // However many arrive here, they caught the player: no heap, no points.
                survivors.append(contentsOf: arriving)
            } else if heaps.contains(position) {
                scrapped += arriving.count
            } else if arriving.count > 1 {
                heaps.insert(position)
                scrapped += arriving.count
            } else {
                survivors.append(contentsOf: arriving)
            }
        }
        let playerCaught = arrivals[player] != nil
        robots = survivors.sorted { $0.id < $1.id }

        let points = scrapped * rules.pointsPerRobot * multiplier
        score += points
        if playerCaught {
            status = .caught
        } else if robots.isEmpty {
            status = .levelCleared
        }
        return TurnOutcome(robotsScrapped: scrapped, pointsEarned: points, turnsTaken: 1)
    }

    private mutating func setUpLevel() {
        status = .playing
        heaps = []
        robots = []
        player = Position(x: rules.width / 2, y: rules.height / 2)
        // Keep a two-cell margin so no robot can catch the player on the first turn.
        let candidates = allCells.filter { $0.chebyshevDistance(to: player) > 2 }
        let count = min(rules.robotCount(forLevel: level), candidates.count)
        for position in candidates.shuffled(using: &generator).prefix(count) {
            robots.append(Robot(id: nextRobotID, position: position))
            nextRobotID += 1
        }
    }
}
