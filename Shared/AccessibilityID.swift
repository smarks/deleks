/// Accessibility identifiers and launch arguments shared by the app and its UI tests.
/// Compiled into both targets so the two can never disagree.
enum AccessibilityID {
    static let board = "board"
    static let player = "player"
    static let robot = "robot"
    static let heap = "heap"
    static let level = "level"
    static let score = "score"
    static let robotsLeft = "robotsLeft"
    static let teleportButton = "teleport"
    static let pulseButton = "pulse"
    static let lastStandButton = "lastStand"
    static let newGameButton = "newGame"
    static let hintsToggle = "hints"
    static let resultCard = "resultCard"
    static let resultActionButton = "resultAction"
}

enum LaunchArgument {
    /// `-deleksSeed <number>` fixes the random seed so a run is repeatable.
    static let seedKey = "deleksSeed"
}

/// UserDefaults keys. Also usable as launch arguments (`-showHints NO`).
enum StorageKey {
    static let showHints = "showHints"
}
