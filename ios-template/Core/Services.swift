/// Service seams (CLAUDE.md rule 3). Real implementations live in the app target;
/// these no-op mocks serve previews and tests.
public enum HapticKind: Sendable { case pickup, snap, place, invalid, lineClear, combo, perfect, lose }
public enum SoundKind: Sendable { case pickup, place, invalid, brickBreak(row: Int), combo(level: Int), refill, win, lose }

public protocol HapticsService: Sendable { func play(_ kind: HapticKind) }
public protocol AudioService: Sendable { func play(_ sound: SoundKind) }

public struct NoHaptics: HapticsService { public init() {}; public func play(_ kind: HapticKind) {} }
public struct NoAudio: AudioService { public init() {}; public func play(_ sound: SoundKind) {} }

/// Single analytics enum (CLAUDE.md rule 10). Names are snake_case; params per CLAUDE.md table.
public enum AnalyticsEvent: Equatable, Sendable {
    case appOpen(sessionIndex: Int)
    case ftueStep(step: Int)
    case levelStart(level: Int, mode: String, attempt: Int)
    case levelComplete(level: Int, mode: String, durationS: Int, attempts: Int, stars: Int, moves: Int, boostersUsed: Int)
    case levelFail(level: Int, mode: String, durationS: Int, attempts: Int, goalProgress: Double)
    case classicEnd(score: Int, best: Int, durationS: Int, linesTotal: Int, maxCombo: Int)
    case linesClear(count: Int, combo: Int, streak: Int, comet: Bool)
    case perfectClear(mode: String, level: Int)

    public var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .ftueStep: return "ftue_step"
        case .levelStart: return "level_start"
        case .levelComplete: return "level_complete"
        case .levelFail: return "level_fail"
        case .classicEnd: return "classic_end"
        case .linesClear: return "lines_clear"
        case .perfectClear: return "perfect_clear"
        }
    }
}

public protocol AnalyticsService: Sendable { func track(_ event: AnalyticsEvent) }
public struct NoAnalytics: AnalyticsService { public init() {}; public func track(_ event: AnalyticsEvent) {} }
