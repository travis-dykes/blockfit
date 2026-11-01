public struct InterstitialConfig: Codable, Equatable, Sendable {
    public var firstLevel = 6              // Play Promise: none before level 6
    public var everyCompletedLevels = 3
    public var minSecondsBetween = 90.0
    public var classicEveryRuns = 1
    public init() {}
}

public enum InterstitialMoment: Equatable, Sendable {
    /// Win/lose card after the result is shown.
    case levelResult(level: Int)
    case classicRunEnd
    /// Never allowed: kept so callers can't accidentally ask.
    case midMove
}

/// Pure decision object (BF-330). Caller supplies `now` in seconds.
public struct InterstitialPolicy: Codable, Equatable, Sendable {
    public var config = InterstitialConfig()
    private var levelsSinceAd = 0
    private var runsSinceAd = 0
    private var lastShown: Double?
    private var lastPurchase: Double?

    public init(config: InterstitialConfig = InterstitialConfig()) { self.config = config }

    public mutating func recordLevelCompleted() { levelsSinceAd += 1 }
    public mutating func recordClassicRun() { runsSinceAd += 1 }
    public mutating func recordPurchase(at now: Double) { lastPurchase = now }

    public func canShow(_ moment: InterstitialMoment, now: Double, removeAds: Bool,
                        isFirstSession: Bool, isLastLevelOfFirstSession: Bool = false) -> Bool {
        if removeAds { return false }
        if let last = lastShown, now - last < config.minSecondsBetween { return false }
        if let p = lastPurchase, now - p < config.minSecondsBetween { return false }
        switch moment {
        case .midMove: return false
        case .levelResult(let level):
            guard level >= config.firstLevel else { return false }
            if isFirstSession && isLastLevelOfFirstSession { return false }
            return levelsSinceAd >= config.everyCompletedLevels
        case .classicRunEnd:
            return runsSinceAd >= config.classicEveryRuns
        }
    }

    public mutating func recordShown(at now: Double) {
        lastShown = now; levelsSinceAd = 0; runsSinceAd = 0
    }
}
