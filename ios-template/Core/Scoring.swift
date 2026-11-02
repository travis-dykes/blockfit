import Foundation

public struct MoveScore: Equatable, Sendable {
    public var cellPoints = 0
    public var linePoints = 0
    public var streak = 0
    public var multiplier = 1.0
    public var perfectClear = false
    public var perfectBonus = 0
    public var total: Int { cellPoints + linePoints + perfectBonus }
}

public enum Scoring {
    /// `lineBase × n × (n+1) / 2` → 10, 30, 60, 100 for n = 1…4.
    public static func lineClearPoints(lines n: Int, config: GameConfig.Scoring) -> Int {
        guard n > 0 else { return 0 }
        return config.lineBase * n * (n + 1) / 2
    }

    /// `streak` = consecutive clearing moves including this one (≥1).
    public static func streakMultiplier(streak: Int, config: GameConfig.Scoring) -> Double {
        guard streak > 1 else { return 1 }
        return min(config.streakCap, 1 + config.streakStep * Double(streak - 1))
    }

    /// - Parameter streak: the streak *after* this move (0 if it cleared nothing).
    public static func score(cellsPlaced: Int, linesCleared: Int, streak: Int,
                             boardEmptyAfter: Bool, config: GameConfig.Scoring) -> MoveScore {
        var s = MoveScore()
        s.cellPoints = cellsPlaced * config.cellPoints
        guard linesCleared > 0 else { return s }
        s.streak = streak
        s.multiplier = streakMultiplier(streak: streak, config: config)
        s.linePoints = Int((Double(lineClearPoints(lines: linesCleared, config: config)) * s.multiplier).rounded())
        if boardEmptyAfter {
            s.perfectClear = true
            s.perfectBonus = config.perfectClearBonus
        }
        return s
    }
}
