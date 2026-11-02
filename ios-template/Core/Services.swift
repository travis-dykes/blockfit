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
    case dailyComplete(date: String, durationS: Int, streakDays: Int)
    case piecePlace(shape: String, linesCleared: Int)        // sampled 10% by the caller
    case currencyEarn(type: String, amount: Int, source: String)
    case currencySpend(type: String, amount: Int, sink: String)
    case boosterUse(type: String, level: Int)
    case adOffer(placement: String, format: String)
    case adShow(placement: String, format: String)
    case adReward(placement: String, format: String)
    case iapView(sku: String, price: String, placement: String)
    case iapPurchase(sku: String, price: String, placement: String)
    case metaUnlock(item: String, category: String)
    case modeUnlock(mode: String)

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
        case .dailyComplete: return "daily_complete"
        case .piecePlace: return "piece_place"
        case .currencyEarn: return "currency_earn"
        case .currencySpend: return "currency_spend"
        case .boosterUse: return "booster_use"
        case .adOffer: return "ad_offer"
        case .adShow: return "ad_show"
        case .adReward: return "ad_reward"
        case .iapView: return "iap_view"
        case .iapPurchase: return "iap_purchase"
        case .metaUnlock: return "meta_unlock"
        case .modeUnlock: return "mode_unlock"
        }
    }
}

public protocol AnalyticsService: Sendable { func track(_ event: AnalyticsEvent) }
public struct NoAnalytics: AnalyticsService { public init() {}; public func track(_ event: AnalyticsEvent) {} }
