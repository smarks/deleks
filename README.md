# deleks

A turn-based robot-chase game for iPhone and iPad, in the one-bit style of an old
desktop accessory. It belongs to the genre of the classic Unix `robots` game.

## How to play

- Tap anywhere on the board to step one square toward that spot. Tap yourself to wait.
- After every move, each robot steps one square toward you.
- Robots that collide turn into a scrap heap. A robot that walks into a heap is scrapped.
- A robot that reaches your square catches you.
- **Teleport** jumps to a random empty square. It might land you next to a robot.
- **Pulse** scraps every robot touching you. You get one per level, and unused pulses carry over.
- **Last stand** holds still until the level ends. Robots scrapped this way score double.
- **Safe-move hints** ring the squares no robot can reach next turn.

On a hardware keyboard, the numeric keypad moves (7 8 9 / 4 5 6 / 1 2 3, with 5 to wait),
and T, P and L trigger the three actions.

## Layout

| Path | What it is |
|------|------------|
| `deleksCore/` | The game engine as a Swift package: pure value types, no UI, seeded randomness. |
| `deleks/` | The SwiftUI app. |
| `Shared/` | Accessibility identifiers compiled into both the app and the UI tests. |
| `deleksUITests/` | UI tests that drive the app with a fixed seed (`-deleksSeed 42`). |
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
