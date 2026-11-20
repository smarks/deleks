import ClankersCore
import Foundation
import Observation

/// Owns the running game and turns taps into engine calls. All game rules live in
/// `ClankersCore`; this type only sequences turns and remembers the high score.
@MainActor
@Observable
final class GameModel {
    private static let highScoreKey = "highScore"
    static let lastStandTurnDelay: Duration = .milliseconds(140)

    private(set) var game: Game
    private(set) var highScore: Int
    /// True while a last stand plays out; every input is refused until it ends.
    private(set) var isRunningLastStand = false
    /// Bumped whenever robots are scrapped, so the view can fire a haptic.
    private(set) var scrapEvents = 0
    /// Bumped for every new game, so the board does not animate old robots into new ones.
    private(set) var gameGeneration = 0

    private let fixedSeed: UInt64?
    private let defaults: UserDefaults

    init(fixedSeed: UInt64? = nil, defaults: UserDefaults = .standard) {
        self.fixedSeed = fixedSeed
        self.defaults = defaults
        highScore = defaults.integer(forKey: Self.highScoreKey)
        game = Game(seed: fixedSeed ?? UInt64.random(in: .min ... .max))
    }

    /// Starts from an exact game. For tests.
    init(game: Game, defaults: UserDefaults) {
        fixedSeed = nil
        self.defaults = defaults
        highScore = defaults.integer(forKey: Self.highScoreKey)
        self.game = game
    }

    static func seedFromLaunchArguments() -> UInt64? {
        guard let text = UserDefaults.standard.string(forKey: LaunchArgument.seedKey) else {
            return nil
        }
        return UInt64(text)
    }

    var acceptsInput: Bool { game.status == .playing && !isRunningLastStand }

    // MARK: - Player actions

    /// A tap anywhere on the board steps one cell toward it; a tap on the player waits.
    func tap(cell: Position) {
        guard acceptsInput else { return }
        play { $0.move(Direction.toward(cell, from: $0.player)) }
    }

    func move(_ direction: Direction) {
        guard acceptsInput else { return }
        play { $0.move(direction) }
    }

    func teleport() {
        guard acceptsInput else { return }
        play { $0.teleport() }
    }

    func pulse() {
        guard acceptsInput, game.pulsesLeft > 0 else { return }
        play { $0.pulse() }
    }

    /// Holds still, one animated turn at a time, until the level ends. The flag is set
    /// before the first await, so a second call (a repeated key) is refused.
    func lastStand() {
        guard acceptsInput else { return }
        isRunningLastStand = true
        Task { await runLastStand() }
    }

    func nextLevel() {
        guard !isRunningLastStand else { return }
        game.nextLevel()
    }

    func newGame() {
        guard !isRunningLastStand else { return }
        gameGeneration += 1
        let seed = fixedSeed.map { $0 &+ UInt64(gameGeneration) } ?? UInt64.random(in: .min ... .max)
        game = Game(seed: seed)
    }

    // MARK: - Turn bookkeeping

    private func runLastStand() async {
        defer { isRunningLastStand = false }
        while true {
            play { $0.holdGround() }
            // Stop the moment the level ends, before any await: otherwise a tap on the
            // result card during the pause would start a stand on the next board.
            guard game.status == .playing else { return }
            do {
                try await Task.sleep(for: Self.lastStandTurnDelay)
            } catch {
                // Sleep only throws on cancellation: finish the stand without animating.
                play { $0.lastStand() }
                return
            }
        }
    }

    private func play(_ action: (inout Game) -> TurnOutcome) {
        let outcome = action(&game)
        if outcome.robotsScrapped > 0 {
            scrapEvents += 1
        }
        if game.score > highScore {
            highScore = game.score
            defaults.set(highScore, forKey: Self.highScoreKey)
        }
    }
}
