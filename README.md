# deleks

A turn-based robot-chase game for iPhone and iPad. It belongs to the genre of the classic
Unix `robots` game, and comes in two looks: the one-bit style of an old desktop accessory,
and a modern, colorful one.

## How to play

- Tap anywhere on the board to step one square toward that spot. Tap yourself to wait.
- After every move, each robot steps one square toward you.
- Robots that collide turn into a scrap heap. A robot that walks into a heap is scrapped.
- A robot that reaches your square catches you.
- **Teleport** jumps to a random empty square. It might land you next to a robot.
- **Pulse** scraps every robot touching you. You get one per level, and unused pulses carry over.
- **Last stand** holds still until the level ends. Robots scrapped this way score double.
- **Safe-move hints** ring the squares no robot can reach next turn.
- **Modern look** switches between the one-bit look and the modern one, which follows the
  system's light or dark mode. The game itself is the same in both.
- **About…**, at the left of the title bar, shows the version, who made the game, its
  license and source, and a little of the history of robot-chase games. It stays up until
  you tap Done.

On a hardware keyboard, the numeric keypad moves (7 8 9 / 4 5 6 / 1 2 3, with 5 to wait),
and T, P and L trigger the three actions.

## Layout

| Path | What it is |
|------|------------|
| `deleksCore/` | The game engine as a Swift package: pure value types, no UI, seeded randomness. |
| `deleks/` | The SwiftUI app. Each look is a `Theme` (`LegacyTheme.swift`, `ModernTheme.swift`); the views ask the current theme how to draw. |
| `Shared/` | Accessibility identifiers, launch arguments and storage keys compiled into both the app and the UI tests, and the About box's wording (`About.json`), bundled into both. |
| `LICENSE` | The MIT License. Bundled into the app, which shows it in the About box. |
| `deleksUITests/` | UI tests that drive the app with a fixed seed (`-deleksSeed 42`), in both looks. |
| `tools/icon/DrawIcon.swift` | Renders the app icon: `swift tools/icon/DrawIcon.swift deleks/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. |
| `tools/upload_testflight.sh` | Archives a clean `main` and uploads it to TestFlight; the build number is main's commit count. |

## Build and test

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is not
committed.

```bash
xcodegen generate
swift test --package-path deleksCore
xcodebuild test -scheme deleks -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

CI runs the engine tests on Linux on every push. The UI tests run locally.
