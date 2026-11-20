/// A cell on the board. `x` grows to the right, `y` grows downward.
public struct Position: Hashable, Sendable, CustomStringConvertible {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func moved(_ direction: Direction) -> Position {
        Position(x: x + direction.deltaX, y: y + direction.deltaY)
    }

    /// One king's-move step from here toward `target` (or no step if already there).
    public func step(toward target: Position) -> Position {
        Position(x: x + (target.x - x).signum(), y: y + (target.y - y).signum())
    }

    /// King's-move distance: the number of turns a robot needs to reach `other`.
    public func chebyshevDistance(to other: Position) -> Int {
        max(abs(other.x - x), abs(other.y - y))
    }

    public var description: String { "\(x),\(y)" }
}

/// The eight king's-move directions plus standing still.
public enum Direction: CaseIterable, Sendable {
    case north, northEast, east, southEast, south, southWest, west, northWest, stay

    public var deltaX: Int {
        switch self {
        case .east, .northEast, .southEast: 1
        case .west, .northWest, .southWest: -1
        case .north, .south, .stay: 0
        }
    }

    public var deltaY: Int {
        switch self {
        case .south, .southEast, .southWest: 1
        case .north, .northEast, .northWest: -1
        case .east, .west, .stay: 0
        }
    }

    /// The direction whose step from `origin` heads toward `target`.
    public static func toward(_ target: Position, from origin: Position) -> Direction {
        let stepDeltaX = (target.x - origin.x).signum()
        let stepDeltaY = (target.y - origin.y).signum()
        return allCases.first { $0.deltaX == stepDeltaX && $0.deltaY == stepDeltaY } ?? .stay
    }
}

/// SplitMix64: small, fast and deterministic, so a seed replays the same game.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
