/// FTUE hint rules (design.md §5): never more than one hint on screen, hints never
/// block input, a skipped hint is never repeated.
public enum HintID: String, Codable, CaseIterable, Sendable {
    case dragPointer, goalChipPulse, undoGlow, steelSparkle, smashGlow, rerollGlow
}

public struct HintSystem: Codable, Equatable, Sendable {
    public private(set) var shown: Set<HintID> = []
    public private(set) var active: HintID?

    public init() {}

    /// Level on which each hint becomes eligible.
    public static func level(for hint: HintID) -> Int {
        switch hint {
        case .dragPointer: return 1
        case .goalChipPulse: return 3
        case .undoGlow: return 4
        case .steelSparkle: return 5
        case .smashGlow: return 6
        case .rerollGlow: return 9
        }
    }

    /// Returns the hint to show now, or nil. Marks it shown immediately so it can't repeat.
    public mutating func request(_ hint: HintID, level: Int) -> HintID? {
        guard active == nil, !shown.contains(hint), level == Self.level(for: hint) else { return nil }
        active = hint
        shown.insert(hint)
        return hint
    }

    /// Player acted or skipped: hint ends and stays consumed.
    public mutating func dismiss() { active = nil }
}
