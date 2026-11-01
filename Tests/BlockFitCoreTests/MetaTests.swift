import Foundation
import Testing
@testable import BlockFitCore

struct BoosterTests {
    private func firstMove(_ s: GameSession) -> (Int, GridPoint)? {
        for slot in s.tray.indices {
            for r in 0..<8 { for c in 0..<8 where s.canPlace(slot: slot, at: GridPoint(row: r, col: c)) {
                return (slot, GridPoint(row: r, col: c))
            } }
        }
        return nil
    }

    @Test func undoRestoresState() {
        var s = GameSession(seed: 11)
        let before = s
        let (slot, at) = firstMove(s)!
        s.place(slot: slot, at: at)
        #expect(s.canUndo)
        #expect(s.undo())
        #expect(s.board == before.board && s.tray == before.tray && s.score == before.score)
        #expect(!s.canUndo)
    }

    @Test func undoNotAcrossRefill() {
        var s = GameSession(seed: 4)
        for _ in 0..<3 { if let (slot, at) = firstMove(s) { s.place(slot: slot, at: at) } }
        if s.traysDealt == 2 { #expect(!s.canUndo) }
    }

    @Test func smashBreaksBrickAndRejectsEmpty() {
        var b = Board(); b[3, 3] = .brick(.red); b[4, 4] = .steel(hits: 2)
        var s = GameSession(seed: 2, board: b)
        #expect(s.smash(at: GridPoint(row: 0, col: 0)) == nil)
        #expect(s.smash(at: GridPoint(row: 3, col: 3))?.clearedCells.count == 1)
        #expect(s.board[3, 3].isEmpty)
        s.smash(at: GridPoint(row: 4, col: 4))
        #expect(s.board[4, 4] == .steel(hits: 1))
    }

    @Test func smashGoldCountsTowardGoal() {
        var b = Board(); b[0, 0] = .gold
        var s = GameSession(seed: 2, board: b, goal: .collectGold(1))
        s.smash(at: GridPoint(row: 0, col: 0))
        #expect(s.isWon)
    }

    @Test func rerollDealsNewTray() {
        var s = GameSession(seed: 8)
        let dealt = s.traysDealt
        #expect(s.reroll())
        #expect(s.traysDealt == dealt + 1 && s.tray.count == 3)
    }
}

struct EconomyTests {
    @Test func rewardMath() {
        let c = EconomyConfig()
        #expect(Wallet.levelReward(stars: 2, dayStreak: 0, rewardedDouble: false, config: c).total == 20)
        #expect(Wallet.levelReward(stars: 2, dayStreak: 0, rewardedDouble: true, config: c).total == 40)
        let capped = Wallet.levelReward(stars: 2, dayStreak: 100, rewardedDouble: false, config: c)
        #expect(capped.streakBonus == 10)   // +50% cap of 20
    }

    @Test func buyRules() throws {
        var w = Wallet(); w.earn(100)
        #expect(throws: EconomyError.insufficientCoins) { try w.buy("theme_neon") }
        try w.buy("trail_spark")
        #expect(w.coins == 20 && w.owned.contains("trail_spark"))
        #expect(throws: EconomyError.alreadyOwned) { try w.buy("trail_spark") }
        #expect(throws: EconomyError.unknownItem) { try w.buy("nope") }
        w.equip("trail_spark")
        #expect(w.equipped[.trail] == "trail_spark")
    }

    @Test func boostersNeverForSale() {
        #expect(SKU.allCases.allSatisfy { !$0.sellsBoosters })
        #expect(CosmeticCatalog.all.allSatisfy { c in Booster.allCases.allSatisfy { $0.rawValue != c.id } })
        var w = Wallet()
        #expect(throws: EconomyError.noBooster) { try w.use(.undo) }
        w.grantBooster(.undo, count: 2)
        #expect(throws: Never.self) { try w.use(.undo) }
        #expect(w.boosters[.undo] == 1)
    }

    @Test func firstTimeGrants() {
        let c = EconomyConfig()
        #expect(Wallet.firstTimeGrants(atLevel: 4, config: c)[.undo] == 2)
        #expect(Wallet.firstTimeGrants(atLevel: 6, config: c)[.smash] == 1)
        #expect(Wallet.firstTimeGrants(atLevel: 9, config: c)[.reroll] == 1)
        #expect(Wallet.firstTimeGrants(atLevel: 5, config: c).isEmpty)
    }

    @Test func thirtyDaySimHasNoDeadZones() {
        for p in [SimPlayer.casual, .light] {
            let r = EconomySim.run(player: p)
            #expect(r.longestDryStreakDays <= 2, "\(p.name)")
            #expect(r.finalLevel == 30 * p.sessionsPerDay * p.levelsPerSession)
            #expect(r.maxStockpileRatio <= 2.0, "\(p.name)")
        }
    }
}

struct SaveTests {
    @Test func roundTrip() throws {
        var s = SaveGame(); s.wallet.earn(42); s.stars[3] = 2; s.dailyCompleted.insert("20261101")
        s.wallet.grantBooster(.smash)
        let back = try SaveMigration.decode(SaveMigration.encode(s))
        #expect(back == s)
    }

    @Test func migratesV1() throws {
        let v1 = #"{"schemaVersion":1,"highestLevel":7,"coins":120,"classicBest":900}"#.data(using: .utf8)!
        let s = try SaveMigration.decode(v1)
        #expect(s.schemaVersion == SaveGame.currentVersion)
        #expect(s.highestLevel == 7 && s.wallet.coins == 120 && s.classicBest == 900)
    }

    @Test func rejectsUnknownFutureVersion() {
        let d = #"{"schemaVersion":99}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) { try SaveMigration.decode(d) }
    }

    @Test func purchaseApplication() {
        var s = SaveGame()
        s.apply(.starterPack)
        #expect(s.removeAds && s.wallet.coins == 300 && s.wallet.owned.contains("theme_neon"))
        s.apply(.coinsS)
        #expect(s.wallet.coins == 400)
    }
}

struct MetaTests {
    @Test func modeGates() {
        #expect(!ModeGate.isUnlocked(.classic, completedLevels: 4))
        #expect(ModeGate.isUnlocked(.classic, completedLevels: 5))
        #expect(ModeGate.isUnlocked(.daily, completedLevels: 8))
        #expect(!ModeGate.isUnlocked(.timeAttack, completedLevels: 19))
        #expect(ModeGate.newlyUnlocked(before: 4, after: 5) == [.classic])
    }

    @Test func dayStreak() {
        var s = DayStreak()
        s.record(day: 10); s.record(day: 11); s.record(day: 11)
        #expect(s.current == 2)
        #expect(s.active(on: 12) == 2 && s.active(on: 13) == 0)
        s.record(day: 20)
        #expect(s.current == 1)
    }

    @Test func dailyPuzzleIdenticalForEveryone() {
        let a = DailyPuzzle.level(year: 2026, month: 11, day: 1)
        let b = DailyPuzzle.level(year: 2026, month: 11, day: 1)
        let c = DailyPuzzle.level(year: 2026, month: 11, day: 2)
        #expect(a == b && a != c)
        #expect(DailyPuzzle.key(year: 2026, month: 11, day: 1) == "20261101")
    }

    @Test func chestEveryFive() {
        let c = EconomyConfig()
        #expect(LevelMap.hasChest(afterLevel: 5, config: c) && !LevelMap.hasChest(afterLevel: 6, config: c))
    }

    @Test func configMerge() {
        let over = #"{"scoring":{"perfectClearBonus":500},"comet":{"enabled":true}}"#.data(using: .utf8)!
        let cfg = ConfigMerge.apply(GameConfig.defaults, overrides: over)
        #expect(cfg.scoring.perfectClearBonus == 500 && cfg.comet.enabled && cfg.scoring.lineBase == 10)
    }
}

struct MonetizationTests {
    @Test func noInterstitialBeforeLevelSix() {
        var p = InterstitialPolicy()
        for _ in 0..<5 { p.recordLevelCompleted() }
        #expect(!p.canShow(.levelResult(level: 5), now: 1000, removeAds: false, isFirstSession: false))
        #expect(p.canShow(.levelResult(level: 6), now: 1000, removeAds: false, isFirstSession: false))
    }

    @Test func everyThreeLevelsAndSpacing() {
        var p = InterstitialPolicy()
        p.recordLevelCompleted(); p.recordLevelCompleted()
        #expect(!p.canShow(.levelResult(level: 8), now: 500, removeAds: false, isFirstSession: false))
        p.recordLevelCompleted()
        #expect(p.canShow(.levelResult(level: 9), now: 500, removeAds: false, isFirstSession: false))
        p.recordShown(at: 500)
        for _ in 0..<3 { p.recordLevelCompleted() }
        #expect(!p.canShow(.levelResult(level: 12), now: 560, removeAds: false, isFirstSession: false))   // <90s
        #expect(p.canShow(.levelResult(level: 12), now: 600, removeAds: false, isFirstSession: false))
    }

    @Test func neverMidMoveOrWithRemoveAdsOrAfterPurchase() {
        var p = InterstitialPolicy()
        for _ in 0..<9 { p.recordLevelCompleted() }
        #expect(!p.canShow(.midMove, now: 1000, removeAds: false, isFirstSession: false))
        #expect(!p.canShow(.levelResult(level: 10), now: 1000, removeAds: true, isFirstSession: false))
        p.recordPurchase(at: 990)
        #expect(!p.canShow(.levelResult(level: 10), now: 1000, removeAds: false, isFirstSession: false))
        #expect(!p.canShow(.levelResult(level: 10), now: 2000, removeAds: false, isFirstSession: true, isLastLevelOfFirstSession: true))
    }

    @Test func starterPackRules() {
        #expect(StarterPackRule.shouldOffer(alreadyShown: false, owned: false, completedLevels: 10, classicScore: nil, justFailedLevel: false))
        #expect(StarterPackRule.shouldOffer(alreadyShown: false, owned: false, completedLevels: 2, classicScore: 1200, justFailedLevel: false))
        #expect(!StarterPackRule.shouldOffer(alreadyShown: true, owned: false, completedLevels: 12, classicScore: nil, justFailedLevel: false))
        #expect(!StarterPackRule.shouldOffer(alreadyShown: false, owned: false, completedLevels: 12, classicScore: nil, justFailedLevel: true))
    }
}
