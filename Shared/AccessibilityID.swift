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
    static let styleToggle = "styleToggle"
    static let resultCard = "resultCard"
    static let resultActionButton = "resultAction"
    static let aboutButton = "about"
    static let aboutBox = "aboutBox"
    static let aboutVersion = "aboutVersion"
    static let aboutCredit = "aboutCredit"
    static let aboutCreditLink = "aboutCreditLink"
    static let aboutLicenseSummary = "aboutLicenseSummary"
    static let aboutLicense = "aboutLicense"
    static let aboutLicenseText = "aboutLicenseText"
    static let aboutSourceLink = "aboutSourceLink"
    static let aboutHistory = "aboutHistory"
    static let aboutDone = "aboutDone"
}

/// Text the app shows that its UI tests look for by name.
enum DisplayText {
    static let gameTitle = "deleks"
}

enum LaunchArgument {
    /// `-deleksSeed <number>` fixes the random seed so a run is repeatable.
    static let seedKey = "deleksSeed"
}

/// UserDefaults keys. Also usable as launch arguments (`-showHints NO`,
/// `-appearanceStyle modern`). A launch argument outranks the saved value for the whole
/// run, so a setting passed that way cannot be changed from inside the app.
enum StorageKey {
    static let showHints = "showHints"
    static let appearanceStyle = "appearanceStyle"
}

/// The look the game is drawn in. Stored under `StorageKey.appearanceStyle` by raw value.
/// Declared here so the UI tests launch each style by the same names the app reads.
enum AppearanceStyle: String, CaseIterable {
    case legacy
    case modern

    /// The style the game is in until the player chooses one.
    static let initial = AppearanceStyle.legacy
}
