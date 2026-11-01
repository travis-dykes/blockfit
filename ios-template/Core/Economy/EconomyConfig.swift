/// All economy tunables (CLAUDE.md rule 4). Starting values from product.md §4.
public struct EconomyConfig: Codable, Equatable, Sendable {
    public var levelBaseCoins = 10
    public var coinsPerStar = 5
    public var chestEveryLevels = 5
    public var chestCoins = 25
    public var dailyPuzzleCoins = 20
    public var streakBonusPerDay = 0.02
    public var streakBonusCap = 0.50
    public var rewardedCoinMultiplier = 2
    public var coinPackSmall = 100, coinPackMedium = 350, coinPackLarge = 700
    /// First-time free booster grants: level → (booster, count). Play Promise: earned, never sold.
    public var boosterGrants: [Int: [Booster: Int]] = [4: [.undo: 2], 6: [.smash: 1], 9: [.reroll: 1]]
    public var dailyFreeBoosterCount = 1
    public init() {}
}

public enum Booster: String, Codable, CaseIterable, Sendable { case undo, smash, reroll }

public enum CosmeticKind: String, Codable, Sendable { case theme, trail, board }

public struct Cosmetic: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var kind: CosmeticKind
    public var name: String
    public var price: Int        // coins; cosmetics are the only coin sink
    public var minLevel: Int     // earliest level it is expected to be affordable (pacing table)
    public init(id: String, kind: CosmeticKind, name: String, price: Int, minLevel: Int) {
        self.id = id; self.kind = kind; self.name = name; self.price = price; self.minLevel = minLevel
    }
}

public enum CosmeticCatalog {
    public static let all: [Cosmetic] = [
        Cosmetic(id: "trail_spark", kind: .trail, name: "Spark", price: 80, minLevel: 4),
        Cosmetic(id: "board_night", kind: .board, name: "Night", price: 100, minLevel: 9),
        Cosmetic(id: "theme_neon", kind: .theme, name: "Neon", price: 250, minLevel: 20),
        Cosmetic(id: "trail_comet", kind: .trail, name: "Comet", price: 150, minLevel: 26),
        Cosmetic(id: "theme_candy", kind: .theme, name: "Candy", price: 400, minLevel: 40),
        Cosmetic(id: "board_cosmos", kind: .board, name: "Cosmos", price: 300, minLevel: 50),
        Cosmetic(id: "trail_rainbow", kind: .trail, name: "Rainbow", price: 300, minLevel: 60),
    ]
    public static func item(_ id: String) -> Cosmetic? { all.first { $0.id == id } }
}
