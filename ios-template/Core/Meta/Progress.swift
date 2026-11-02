public enum GameMode: String, Codable, CaseIterable, Sendable { case levels, classic, daily, timeAttack }

/// Completion → Modes (product.md §3): Classic at L5, Daily at L8, Time Attack at L20.
public enum ModeGate {
    public static func unlockLevel(_ mode: GameMode) -> Int {
        switch mode {
        case .levels: return 1
        case .classic: return 5
        case .daily: return 8
        case .timeAttack: return 20
        }
    }
    /// `completedLevels` = number of levels beaten.
    public static func isUnlocked(_ mode: GameMode, completedLevels: Int) -> Bool {
        completedLevels >= unlockLevel(mode) || mode == .levels
    }
    public static func newlyUnlocked(before: Int, after: Int) -> [GameMode] {
        GameMode.allCases.filter { !isUnlocked($0, completedLevels: before) && isUnlocked($0, completedLevels: after) }
    }
}

/// Consecutive-day streak, fed by Daily Puzzle completions. Days are integer day numbers
/// (e.g. days since epoch) so Core stays free of Calendar/timezones.
public struct DayStreak: Codable, Equatable, Sendable {
    public private(set) var current = 0
    public private(set) var lastDay: Int?
    public init() {}

    public mutating func record(day: Int) {
        guard let last = lastDay else { current = 1; lastDay = day; return }
        if day == last { return }
        current = (day == last + 1) ? current + 1 : 1
        lastDay = day
    }

    /// Streak as shown on a given day (breaks if a day was skipped).
    public func active(on day: Int) -> Int {
        guard let last = lastDay else { return 0 }
        return day - last <= 1 ? current : 0
    }
}

/// Daily Puzzle: one fixed seeded board per day, identical for everyone (rule 2).
public enum DailyPuzzle {
    public static let salt: UInt64 = 0xDA11

    public static func level(year: Int, month: Int, day: Int) -> LevelData {
        let seed = SeededRNG.dailySeed(year: year, month: month, day: day, salt: salt)
        var rng = SeededRNG(seed: seed)
        let params = LevelParams(fillRatio: 0.38, goalCount: 5, steelRatio: 0.08, trayGuarantee: 10, par: 7)
        var lv = LevelGenerator.candidate(id: 0, params: params, rng: &rng)
        lv.seed = seed
        return lv
    }

    public static func key(year: Int, month: Int, day: Int) -> String {
        String(year * 10_000 + month * 100 + day)
    }
}

/// Map layout: a chest every N levels.
public enum LevelMap {
    public static func hasChest(afterLevel level: Int, config: EconomyConfig) -> Bool {
        config.chestEveryLevels > 0 && level % config.chestEveryLevels == 0
    }
}

/// ProgressionKit seam (CLAUDE.md rule 9). The package isn't linked in this repo yet; this
/// protocol is what Block Fit emits so the adapter can forward to ProgressionKit.
public enum PlayEvent: Equatable, Sendable {
    case levelCompleted(level: Int, stars: Int)
    case modeUnlocked(GameMode)
    case dailyCompleted(dayNumber: Int)
    case coinsEarned(Int, source: String)
    case collectionUnlocked(id: String)
}

public protocol ProgressionAdapter: Sendable { func emit(_ event: PlayEvent) }
public struct NoProgression: ProgressionAdapter { public init() {}; public func emit(_ event: PlayEvent) {} }
