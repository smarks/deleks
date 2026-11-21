import SwiftUI
import Testing

@testable import deleks

/// The modern look's motion is chosen from the Reduce Motion setting alone, so both
/// choices can be checked here without changing the simulator's settings.
@Suite("Modern motion")
@MainActor
struct ModernMotionTests {
    private let legacy = LegacyTheme()

    @Test func reduceMotionChoosesTheReducedSet() {
        #expect(ModernMotion(reduceMotion: true) == .reduced)
        #expect(ModernMotion(reduceMotion: false) == .full)
    }

    @Test func reducedMotionMovesExactlyAsTheLegacyLookDoes() {
        let reduced = ModernMotion.reduced
        #expect(reduced.turnAnimation == legacy.turnAnimation)
        #expect(structure(of: reduced.heapTransition) == structure(of: legacy.heapTransition))
        #expect(structure(of: reduced.robotTransition) == structure(of: legacy.robotTransition))
        #expect(structure(of: reduced.cardTransition) == structure(of: .opacity))
    }

    @Test func fullMotionIsTheModernLooksOwn() {
        let full = ModernMotion.full
        #expect(full.turnAnimation != legacy.turnAnimation)
        #expect(structure(of: full.heapTransition) != structure(of: legacy.heapTransition))
        #expect(structure(of: full.robotTransition) != structure(of: legacy.robotTransition))
        #expect(structure(of: full.cardTransition) != structure(of: .opacity))
    }

    /// `AnyTransition` cannot be compared, so compare what two transitions are made of:
    /// the kinds of transition inside and the numbers they hold.
    private func structure(of transition: AnyTransition) -> String {
        var description = ""
        dump(transition, to: &description)
        return description
    }
}
