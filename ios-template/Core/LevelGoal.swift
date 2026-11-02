public enum LevelGoal: Codable, Equatable, Sendable {
    case collectGold(Int)
    case reachScore(Int)
    case clearLines(Int)

    public func progress(gold: Int, score: Int, lines: Int) -> Int {
        switch self {
        case .collectGold: return gold
        case .reachScore: return score
        case .clearLines: return lines
        }
    }

    public var target: Int {
        switch self {
        case .collectGold(let n), .reachScore(let n), .clearLines(let n): return n
        }
    }
}

/// Stars (product.md §3): 1 = goal met, 2 = within par + slack, 3 = at or under par.
/// Booster use caps stars at 2 once boosters exist (M3).
public enum Stars {
    public static func rate(moves: Int, par: Int, boostersUsed: Int = 0, slack: Int = 2) -> Int {
        if moves <= par && boostersUsed == 0 { return 3 }
        if moves <= par + slack { return 2 }
        return 1
    }
}
