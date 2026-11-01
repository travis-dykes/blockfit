import SwiftUI
import SpriteKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

struct WinInfo: Equatable {
    var level: Int
    var stars: Int
    var reward: CoinReward
    var newModes: [GameMode]
    var chest: Bool
}

enum Route: Equatable { case home, map, shop, settings, play }
enum Overlay: Equatable { case none, win(WinInfo), lose, classicOver(score: Int, best: Int), starterPack }

/// Level source: bundled hand-built L1–10, generated (seeded, solver-validated) beyond.
enum LevelRepository {
    nonisolated(unsafe) private static var cache: [Int: LevelData] = [:]
    static func level(_ id: Int) -> LevelData {
        if let c = cache[id] { return c }
        var lv: LevelData?
        if let url = Bundle.main.url(forResource: String(format: "level_%02d", id), withExtension: "json"),
           let d = try? Data(contentsOf: url) { lv = try? LevelLoader.decode(d) }
        if lv == nil {
            lv = LevelGenerator.generate(id: id) ?? {
                var rng = SeededRNG(seed: UInt64(id))
                return LevelGenerator.candidate(id: id, params: LevelGenerator.params(forLevel: id), rng: &rng)
            }()
        }
        cache[id] = lv!
        return lv!
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var save: SaveGame { didSet { store.save(save); Haptics.enabled = save.settings.haptics } }
    @Published var route: Route = .home
    @Published var overlay: Overlay = .none
    @Published var scene: BoardScene?
    @Published var mode: GameMode = .levels
    @Published var currentLevel = 1
    @Published var boostersTick = 0

    let store: SaveStore
    var config: ConfigService
    var ads: AdService
    var storeService: StoreService
    var analytics: AnalyticsService
    var progression: ProgressionAdapter
    private var interstitial = InterstitialPolicy()
    private var levelStart = Date()
    private var attempts: [Int: Int] = [:]
    private var boostersUsed = 0
    private var continued = false

    init(store: SaveStore, config: ConfigService = LocalConfigService(), ads: AdService = NoAdsService(),
         storeService: StoreService = MockStore(), analytics: AnalyticsService = NoAnalytics(),
         progression: ProgressionAdapter = NoProgression()) {
        self.store = store; self.config = config; self.ads = ads; self.storeService = storeService
        self.analytics = analytics; self.progression = progression
        var s = store.load(); s.sessionIndex += 1
        self.save = s
        store.save(s)
        Haptics.enabled = s.settings.haptics
        analytics.track(.appOpen(sessionIndex: s.sessionIndex))
        // FTUE: first launch goes straight into Level 1 (design.md §4).
        if s.sessionIndex == 1 && s.highestLevel == 1 { startLevel(1) }
    }

    var completedLevels: Int { save.highestLevel - 1 }
    var economy: EconomyConfig { config.economyConfig() }
    var now: Double { Date().timeIntervalSince1970 }
    var today: Int { Int(now / 86_400) }

    // MARK: Starting modes
    func startLevel(_ n: Int) {
        mode = .levels; currentLevel = n; overlay = .none; continued = false; boostersUsed = 0
        attempts[n, default: 0] += 1
        if !save.grantedAt.contains(n) {
            for (b, c) in Wallet.firstTimeGrants(atLevel: n, config: economy) { save.wallet.grantBooster(b, count: c) }
            save.grantedAt.insert(n)
        }
        let lv = LevelRepository.level(n)
        guard let session = try? LevelLoader.makeSession(lv, config: config.gameConfig()) else { route = .home; return }
        present(session: session, seed: lv.seed)
        analytics.track(.levelStart(level: n, mode: "levels", attempt: attempts[n] ?? 1))
    }

    func startClassic() {
        guard ModeGate.isUnlocked(.classic, completedLevels: completedLevels) else { return }
        mode = .classic; overlay = .none
        let seed = UInt64(save.sessionIndex) &* 7_919 &+ UInt64(save.classicBest)
        let session = GameSession(seed: seed, config: config.gameConfig())
        present(session: session, seed: seed)
        analytics.track(.levelStart(level: 0, mode: "classic", attempt: 1))
    }

    func startDaily() {
        guard ModeGate.isUnlocked(.daily, completedLevels: completedLevels) else { return }
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
        let key = DailyPuzzle.key(year: c.year!, month: c.month!, day: c.day!)
        guard !save.dailyCompleted.contains(key) else { return }
        mode = .daily; overlay = .none; continued = false; boostersUsed = 0
        let lv = DailyPuzzle.level(year: c.year!, month: c.month!, day: c.day!)
        guard let session = try? LevelLoader.makeSession(lv, config: config.gameConfig()) else { return }
        present(session: session, seed: lv.seed)
    }

    private func present(session: GameSession, seed: UInt64) {
        let sc = BoardScene(session: session, seed: seed)
        sc.onLevelWon = { [weak self] moves in self?.levelWon(moves: moves) }
        sc.onLevelLost = { [weak self] in self?.overlay = .lose }
        sc.onGameOver = { [weak self] score in self?.classicEnded(score: score) }
        sc.onBoostersChanged = { [weak self] in self?.boostersTick += 1 }
        scene = sc; levelStart = Date(); route = .play
    }

    // MARK: Results
    private func levelWon(moves: Int) {
        let duration = Int(Date().timeIntervalSince(levelStart))
        if mode == .daily {
            let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
            save.dailyCompleted.insert(DailyPuzzle.key(year: c.year!, month: c.month!, day: c.day!))
            save.dayStreak.record(day: today)
            save.wallet.earn(economy.dailyPuzzleCoins)
            progression.emit(.dailyCompleted(dayNumber: today))
            analytics.track(.dailyComplete(date: "\(today)", durationS: duration, streakDays: save.dayStreak.current))
            overlay = .win(WinInfo(level: 0, stars: 3, reward: CoinReward(base: economy.dailyPuzzleCoins, streakBonus: 0),
                                   newModes: [], chest: false))
            return
        }
        let n = currentLevel
        let par = LevelRepository.level(n).par
        let stars = Stars.rate(moves: moves, par: par, boostersUsed: boostersUsed)
        let before = completedLevels
        save.stars[n] = max(save.stars[n] ?? 0, stars)
        save.highestLevel = max(save.highestLevel, n + 1)
        let newModes = ModeGate.newlyUnlocked(before: before, after: completedLevels)
        newModes.forEach { analytics.track(.modeUnlock(mode: $0.rawValue)); progression.emit(.modeUnlocked($0)) }
        let reward = Wallet.levelReward(stars: stars, dayStreak: save.dayStreak.active(on: today),
                                        rewardedDouble: false, config: economy)
        interstitial.recordLevelCompleted()
        progression.emit(.levelCompleted(level: n, stars: stars))
        analytics.track(.levelComplete(level: n, mode: "levels", durationS: duration, attempts: attempts[n] ?? 1,
                                       stars: stars, moves: moves, boostersUsed: boostersUsed))
        overlay = .win(WinInfo(level: n, stars: stars, reward: reward, newModes: newModes,
                               chest: LevelMap.hasChest(afterLevel: n, config: economy)))
        maybeInterstitial(level: n)
    }

    private func classicEnded(score: Int) {
        guard mode == .classic else { return }
        let best = max(save.classicBest, score)
        save.classicBest = best
        interstitial.recordClassicRun()
        analytics.track(.classicEnd(score: score, best: best, durationS: Int(Date().timeIntervalSince(levelStart)),
                                    linesTotal: scene?.session.linesTotal ?? 0, maxCombo: scene?.session.maxCombo ?? 0))
        overlay = StarterPackRule.shouldOffer(alreadyShown: save.starterPackShown, owned: save.removeAds,
                                              completedLevels: completedLevels, classicScore: score, justFailedLevel: false)
            ? .starterPack : .classicOver(score: score, best: best)
        if overlay == .starterPack { save.starterPackShown = true }
        else if case .classicOver = overlay { maybeClassicInterstitial() }
    }

    /// Interstitials run only after the result card is on screen (Play Promise).
    private func maybeInterstitial(level: Int) {
        guard interstitial.canShow(.levelResult(level: level), now: now, removeAds: save.removeAds,
                                   isFirstSession: save.sessionIndex == 1) else { return }
        interstitial.recordShown(at: now)
        Task { await ads.showInterstitial() }
    }
    private func maybeClassicInterstitial() {
        guard interstitial.canShow(.classicRunEnd, now: now, removeAds: save.removeAds,
                                   isFirstSession: save.sessionIndex == 1) else { return }
        interstitial.recordShown(at: now)
        Task { await ads.showInterstitial() }
    }

    // MARK: Cards
    func collect(_ info: WinInfo) {
        save.wallet.earn(info.reward.total)
        analytics.track(.currencyEarn(type: "coins", amount: info.reward.total, source: "level_complete"))
        if info.chest { save.wallet.earn(economy.chestCoins) }
        // Starter pack: after L10, once, calm card, never right after a fail.
        if info.level > 0, StarterPackRule.shouldOffer(alreadyShown: save.starterPackShown, owned: save.removeAds,
                                                      completedLevels: completedLevels, classicScore: nil, justFailedLevel: false) {
            save.starterPackShown = true; overlay = .starterPack; return
        }
        overlay = .none; route = .map
    }

    func collectDouble(_ info: WinInfo) {
        Task {
            analytics.track(.adOffer(placement: "double_coins", format: "rewarded"))
            if await ads.showRewarded(.doubleCoins) {
                analytics.track(.adReward(placement: "double_coins", format: "rewarded"))
                save.wallet.earn(info.reward.total)       // the extra half
            }
            collect(info)
        }
    }

    func nextLevel(after info: WinInfo) { collect(info); if overlay == .none { startLevel(info.level + 1) } }
    func retry() { if mode == .levels { startLevel(currentLevel) } else if mode == .classic { startClassic() } }

    /// One continue per level: rewarded, then a fresh tray.
    func continueAfterFail() {
        guard !continued else { return }
        Task {
            analytics.track(.adOffer(placement: "continue", format: "rewarded"))
            if await ads.showRewarded(.continueAfterFail) {
                analytics.track(.adReward(placement: "continue", format: "rewarded"))
                continued = true
                overlay = .none
                _ = scene?.performReroll()
            }
        }
    }
    var canContinue: Bool { !continued }

    // MARK: Boosters
    func useBooster(_ b: Booster) {
        guard overlay == .none, (save.wallet.boosters[b] ?? 0) > 0 else { return }
        var ok = false
        switch b {
        case .undo: ok = scene?.canUndo == true
        case .reroll: ok = true
        case .smash: ok = true
        }
        guard ok else { return }
        try? save.wallet.use(b)
        boostersUsed += 1
        analytics.track(.boosterUse(type: b.rawValue, level: currentLevel))
        switch b {
        case .undo: if scene?.performUndo() != true { save.wallet.grantBooster(.undo); boostersUsed -= 1 }
        case .reroll: if scene?.performReroll() != true { save.wallet.grantBooster(.reroll); boostersUsed -= 1 }
        case .smash: scene?.beginSmash()
        }
        boostersTick += 1
    }

    /// Booster refill by rewarded video (inventory view, never a store).
    func watchForBooster(_ b: Booster) {
        Task {
            if await ads.showRewarded(.dailyBooster) { save.wallet.grantBooster(b); analytics.track(.adReward(placement: "booster", format: "rewarded")) }
        }
    }

    var dailyFreeBoosterAvailable: Bool { save.lastFreeBoosterDay != today }
    func claimDailyFreeBooster(_ b: Booster) {
        guard dailyFreeBoosterAvailable else { return }
        Task {
            if await ads.showRewarded(.dailyBooster) {
                save.wallet.grantBooster(b, count: economy.dailyFreeBoosterCount); save.lastFreeBoosterDay = today
            }
        }
    }

    // MARK: Shop / purchases
    func buy(_ id: String) {
        guard (try? save.wallet.buy(id)) != nil else { return }
        analytics.track(.currencySpend(type: "coins", amount: CosmeticCatalog.item(id)?.price ?? 0, sink: id))
        analytics.track(.metaUnlock(item: id, category: CosmeticCatalog.item(id)?.kind.rawValue ?? ""))
        progression.emit(.collectionUnlocked(id: id))
        save.wallet.equip(id)
    }

    func purchase(_ sku: SKU, placement: String) {
        Task {
            analytics.track(.iapView(sku: sku.rawValue, price: "\(sku.startingPriceCents)", placement: placement))
            if await storeService.purchase(sku) == .purchased {
                save.apply(sku, economy: economy)
                interstitial.recordPurchase(at: now)
                analytics.track(.iapPurchase(sku: sku.rawValue, price: "\(sku.startingPriceCents)", placement: placement))
            }
            if overlay == .starterPack { overlay = .none; route = .home }
        }
    }

    func restorePurchases() {
        Task { for sku in await storeService.restore() { save.apply(sku, economy: economy) } }
    }

    func goHome() { overlay = .none; route = .home; scene = nil }
}
