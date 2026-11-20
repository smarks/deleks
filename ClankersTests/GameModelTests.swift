import ClankersCore
import Foundation
import Testing

@testable import Clankers

@MainActor
@Suite("Game model")
struct GameModelTests {
    private let defaults: UserDefaults

    init() throws {
        let suiteName = "GameModelTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    /// Two robots that collide on the first turn of a last stand, clearing the level.
    private func oneTurnStand() -> Game {
        let rules = GameRules()
        let player = Position(x: rules.width / 2, y: rules.height / 2)
        return Game(
            rules: rules, seed: 1, player: player,
            robots: [
                Position(x: player.x - 2, y: player.y),
                Position(x: player.x - 2, y: player.y - 1),
            ])
    }

    private func waitForLastStandToEnd(_ model: GameModel) async throws {
        for _ in 0..<200 where model.isRunningLastStand {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!model.isRunningLastStand)
    }

    @Test func lastStandStopsWhenTheLevelEnds() async throws {
        let model = GameModel(game: oneTurnStand(), defaults: defaults)
        model.lastStand()
        #expect(model.isRunningLastStand)
        try await waitForLastStandToEnd(model)
        #expect(model.game.status == .levelCleared)
        #expect(model.game.turn == 1)
    }

    @Test func nextLevelRightAfterALastStandDoesNotStartAnother() async throws {
        let model = GameModel(game: oneTurnStand(), defaults: defaults)
        model.lastStand()
        // Press "Next level" the moment the card can appear, which is when the old loop
        // was still sleeping and would carry the stand onto the new board.
        for _ in 0..<200 where model.game.status == .playing {
            try await Task.sleep(for: .milliseconds(1))
        }
        #expect(model.game.status == .levelCleared)
        model.nextLevel()
        #expect(model.game.level == 2)
        let turnOnNewLevel = model.game.turn
        try await Task.sleep(for: GameModel.lastStandTurnDelay * 3)
        #expect(model.game.status == .playing)
        #expect(model.game.turn == turnOnNewLevel)
        #expect(model.acceptsInput)
    }

    @Test func secondLastStandCallIsRefused() async throws {
        let model = GameModel(game: oneTurnStand(), defaults: defaults)
        model.lastStand()
        model.lastStand()
        try await waitForLastStandToEnd(model)
        #expect(model.game.turn == 1)
    }

    @Test func newGameIsRefusedDuringALastStand() async throws {
        let rules = GameRules()
        let player = Position(x: rules.width / 2, y: rules.height / 2)
        let slowStand = Game(rules: rules, seed: 1, player: player, robots: [Position(x: 0, y: 0)])
        let model = GameModel(game: slowStand, defaults: defaults)
        model.lastStand()
        model.newGame()
        #expect(model.gameGeneration == 0)
        try await waitForLastStandToEnd(model)
        #expect(model.game.status == .caught)
    }

    @Test func highScoreIsSavedAndReloaded() async throws {
        let model = GameModel(game: oneTurnStand(), defaults: defaults)
        model.lastStand()
        try await waitForLastStandToEnd(model)
        #expect(model.highScore > 0)
        let reloaded = GameModel(fixedSeed: 1, defaults: defaults)
        #expect(reloaded.highScore == model.highScore)
    }

    @Test func inputIsIgnoredAfterBeingCaught() {
        let rules = GameRules()
        let player = Position(x: rules.width / 2, y: rules.height / 2)
        let model = GameModel(
            game: Game(rules: rules, seed: 1, player: player, robots: [Position(x: player.x + 1, y: player.y)]),
            defaults: defaults)
        model.move(.stay)
        #expect(model.game.status == .caught)
        let turn = model.game.turn
        model.teleport()
        model.pulse()
        model.tap(cell: Position(x: 0, y: 0))
        #expect(model.game.turn == turn)
    }
}
