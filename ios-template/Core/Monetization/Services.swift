public enum SKU: String, CaseIterable, Sendable {
    case removeAds = "blockfit.remove_ads"
    case starterPack = "blockfit.starter_pack"
    case coinsS = "blockfit.coins_s", coinsM = "blockfit.coins_m", coinsL = "blockfit.coins_l"

    /// Starting price in USD cents (display price comes from the store at runtime).
    public var startingPriceCents: Int {
        switch self {
        case .removeAds: return 399
        case .starterPack: return 299
        case .coinsS: return 99
        case .coinsM: return 299
        case .coinsL: return 499
        }
    }
    /// Coins never buy boosters and no SKU sells boosters (Play Promise).
    public var sellsBoosters: Bool { false }
}

public enum PurchaseResult: Equatable, Sendable { case purchased, cancelled, failed }

public protocol StoreService: Sendable {
    func purchase(_ sku: SKU) async -> PurchaseResult
    func restore() async -> Set<SKU>
}

/// Debug/preview store: everything succeeds instantly.
public struct MockStore: StoreService {
    public init() {}
    public func purchase(_ sku: SKU) async -> PurchaseResult { .purchased }
    public func restore() async -> Set<SKU> { [] }
}

public enum RewardedPlacement: String, Sendable { case continueAfterFail, doubleCoins, dailyBooster }

public protocol AdService: Sendable {
    func showRewarded(_ placement: RewardedPlacement) async -> Bool
    func showInterstitial() async
}
/// DEBUG default (CLAUDE.md rule 3). Rewarded always "completes" so flows are testable.
public struct NoAdsService: AdService {
    public init() {}
    public func showRewarded(_ placement: RewardedPlacement) async -> Bool { true }
    public func showInterstitial() async {}
}

/// Starter pack shows once: after L10, or the first lost Classic run past 1,000 points.
/// Never right after a fail with a timer; one calm card.
public enum StarterPackRule {
    public static func shouldOffer(alreadyShown: Bool, owned: Bool, completedLevels: Int,
                                   classicScore: Int?, justFailedLevel: Bool) -> Bool {
        guard !alreadyShown, !owned, !justFailedLevel else { return false }
        if completedLevels >= 10 { return true }
        if let s = classicScore, s > 1_000 { return true }
        return false
    }
}

public struct Entitlements: Codable, Equatable, Sendable {
    public var removeAds = false
    public var starterPack = false
    public init() {}
    /// Starter pack = Remove Ads + "Neon" theme + 300 coins.
    public static let starterPackCoins = 300
    public static let starterPackCosmetic = "theme_neon"
}

public extension SaveGame {
    /// Applies a successful purchase. Consumable coin packs add coins; cosmetics-only for coins.
    mutating func apply(_ sku: SKU, economy: EconomyConfig = EconomyConfig()) {
        switch sku {
        case .removeAds: removeAds = true
        case .starterPack:
            removeAds = true
            wallet.earn(Entitlements.starterPackCoins)
            wallet.owned.insert(Entitlements.starterPackCosmetic)
        case .coinsS: wallet.earn(economy.coinPackSmall)
        case .coinsM: wallet.earn(economy.coinPackMedium)
        case .coinsL: wallet.earn(economy.coinPackLarge)
        }
    }
}
