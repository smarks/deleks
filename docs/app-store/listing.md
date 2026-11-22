# App Store listing

What goes into App Store Connect for deleks version 1.0. App Store Connect is the copy that
counts; this file records what was entered and why, so the next version starts from it.

## App information

| Field | Value |
|-------|-------|
| Name | Deleks |
| Subtitle | Outwit the robots |
| Bundle ID | com.origamisoftware.deleks |
| SKU | deleks |
| Primary language | English (U.S.) |
| Primary category | Games, with the subcategories Puzzle and Strategy (Games allows up to two) |
| Secondary category | none |
| Content rights | No third-party content |
| Age rating | 4+ (every questionnaire answer "None"; robots crash into scrap, nothing is shown being hurt) |
| Price | US$0.99, all territories (App Store Connect sets each territory's equivalent). Needs the Paid Apps agreement, with banking and tax details, active in App Store Connect under Business. |
| Copyright | 2026 Spencer Marks |

## URLs

| Field | Value |
|-------|-------|
| Support URL | https://github.com/smarks/deleks/issues |
| Marketing URL | https://github.com/smarks/deleks |
| Privacy policy URL | https://github.com/smarks/deleks/blob/main/PRIVACY.md |

## App privacy

Data Not Collected. The app has no network code, no analytics and no third-party SDKs; it
stores only its own settings on the device (see `PRIVACY.md`).

## Version 1.0 text

**Promotional text** (170 characters at most)

> A pocket-sized robot-chase puzzle. Step, teleport or pulse your way out, and trick every robot into crashing. Play in a classic one-bit look or a modern, colorful one.

**Description**

> The robots are closing in, one square for every step you take. You can't fight them, but you can outthink them: when two robots land on the same square, they crash into a heap of scrap, and any robot that walks into a heap is scrapped too. Clear the board and the next level brings more of them.
>
> • Move one square at a time in any direction, or stay put.
> • Teleport to a random square when you're cornered — but you might land next to a robot.
> • Pulse scraps every robot touching you. You get one per level, and unused pulses carry over.
> • Last stand holds your ground until the level ends, for double points.
> • Safe-move hints show the squares no robot can reach next turn.
>
> Play in a crisp one-bit look inspired by early desktop computers, or switch to a modern, colorful look with its own light and dark modes. Works with VoiceOver, Dynamic Type, Reduce Motion and a hardware keyboard.
>
> No ads, no in-app purchases, no accounts and no tracking. deleks is open source under the MIT License.

**Keywords** (100 characters at most)

> chase,turn-based,tactics,retro,classic,grid,teleport,one-bit,brain,logic,scrap,heaps,survival,arcade

**What's new**: not shown for a first version.

## App Review

- Sign-in required: no.
- Notes: "No account or network access. Tap a square to move; the About button shows the license and source."
- Contact (first name, last name, phone, email): entered by Spencer in App Store Connect.

## Screenshots

App Store Connect needs two sets for an app that runs on iPhone and iPad: iPhone 6.9"
(1320 × 2868) and iPad 13" (2064 × 2752). The `deleksStoreScreenshots` scheme takes both,
playing seed 42 so the boards repeat. For each look it saves the opening board, a game in
progress with scrap heaps, a cleared level and the About box. The sets are in
`docs/app-store/screenshots/iphone-6.9/` and `docs/app-store/screenshots/ipad-13/`; upload
them in file-name order.

To retake them, on an iPhone Pro Max and an iPad Pro 13-inch simulator set to English, each
with the app freshly installed. On iPad the run first switches the simulator's Multitasking
setting to Full Screen Apps and leaves it there; the iPad status bar keeps showing the
simulator's real date beside 9:41.

```bash
xcrun simctl status_bar <device> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
TEST_RUNNER_SCREENSHOT_DIR=<folder> xcodebuild test -scheme deleksStoreScreenshots -destination 'platform=iOS Simulator,id=<device>'
```
