import Foundation
import Combine

/// DEBUG-only knobs (CLAUDE.md debug menu stub): Comet Clear toggle, seed, Gate 0 combo setup.
@MainActor
final class DebugSettings: ObservableObject {
    @Published var cometEnabled = false
    @Published var seedText = ""
    /// Bumped to ask the scene to restart with the current settings.
    @Published var restartToken = 0
    @Published var comboSetup = false

    var seed: UInt64? { UInt64(seedText) }

    func restart(comboSetup: Bool = false) {
        self.comboSetup = comboSetup
        restartToken += 1
    }
}
