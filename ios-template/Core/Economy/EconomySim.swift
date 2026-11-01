/// 30-day economy simulation (BF-300 / Gate 3). Simulated players "complete" levels at
/// a fixed star rate and buy the cheapest cosmetic they can afford in catalog order.
public struct SimPlayer: Sendable {
    public var name: String
    public var sessionsPerDay: Int
    public var levelsPerSession: Int
    public var rewardedOptIn: Double
    public var avgStars: Int
    public static let casual = SimPlayer(name: "casual", sessionsPerDay: 3, levelsPerSession: 4, rewardedOptIn: 0.3, avgStars: 2)
    public static let light = SimPlayer(name: "light", sessionsPerDay: 1, levelsPerSession: 4, rewardedOptIn: 0.3, avgStars: 2)
}

public struct SimReport: Sendable {
    public var finalLevel = 0
    public var finalCoins = 0
    public var purchases: [(day: Int, id: String)] = []
    public var longestDryStreakDays = 0      // days with nothing affordable AND nothing bought
    public var maxStockpileRatio = 0.0       // coins / next price
}

public enum EconomySim {
    public static func run(player: SimPlayer, days: Int = 30, config: EconomyConfig = EconomyConfig(), seed: UInt64 = 1) -> SimReport {
        var rng = SeededRNG(seed: seed)
        var wallet = Wallet()
        var level = 0
        var report = SimReport()
        var dry = 0
        let catalog = CosmeticCatalog.all.sorted { $0.price < $1.price }
        for day in 1...days {
            var boughtToday = false
            for _ in 0..<player.sessionsPerDay {
                for _ in 0..<player.levelsPerSession {
                    level += 1
                    let double = rng.nextUnit() < player.rewardedOptIn
                    wallet.earn(Wallet.levelReward(stars: player.avgStars, dayStreak: min(day, 25),
                                                   rewardedDouble: double, config: config).total)
                    if LevelMap.hasChest(afterLevel: level, config: config) { wallet.earn(config.chestCoins) }
                }
                while let next = catalog.first(where: { !wallet.owned.contains($0.id) && $0.price <= wallet.coins }) {
                    try? wallet.buy(next.id); report.purchases.append((day, next.id)); boughtToday = true
                }
            }
            let nextPrice = catalog.first { !wallet.owned.contains($0.id) }?.price
            let affordable = nextPrice.map { $0 <= wallet.coins } ?? true
            dry = (boughtToday || affordable) ? 0 : dry + 1
            report.longestDryStreakDays = max(report.longestDryStreakDays, dry)
            if let np = nextPrice { report.maxStockpileRatio = max(report.maxStockpileRatio, Double(wallet.coins) / Double(np)) }
        }
        report.finalLevel = level; report.finalCoins = wallet.coins
        return report
    }
}
