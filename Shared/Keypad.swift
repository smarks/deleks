import deleksCore

/// The numeric-keypad keys that move the player, laid out as on the keypad: 7 8 9 above,
/// 4 5 6 in the middle (5 waits), 1 2 3 below. Shared so the app and the screenshot run
/// read the same layout.
enum Keypad {
    static let directions: [Character: Direction] = [
        "7": .northWest, "8": .north, "9": .northEast,
        "4": .west, "5": .stay, "6": .east,
        "1": .southWest, "2": .south, "3": .southEast,
    ]
}
