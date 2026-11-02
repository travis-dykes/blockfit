import UIKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

/// UIKit-generator haptics honouring the Settings toggle. Core Haptics combo patterns: BF-110 follow-up.
@MainActor
struct SystemHaptics: HapticsService {
    func play(_ kind: HapticKind) {
        switch kind {
        case .pickup: Haptics.impact(.light)
        case .snap: Haptics.selection()
        case .place: Haptics.impact(.medium)
        case .invalid: Haptics.impact(.soft)
        case .lineClear: Haptics.impact(.rigid)
        case .combo, .perfect: Haptics.impact(.heavy)
        case .lose: Haptics.warning()
        }
    }
}
