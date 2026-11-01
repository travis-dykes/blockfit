public enum EconomyError: Error, Equatable { case insufficientCoins, alreadyOwned, unknownItem, noBooster }

public struct CoinReward: Equatable, Sendable {
    public var base: Int
    public var streakBonus: Int
    public var total: Int { base + streakBonus }
}

/// Wallet + inventory + faucet/sink rules. Pure value type; persisted via SaveGame.
public struct Wallet: Codable, Equatable, Sendable {
    public var coins = 0
    public var boosters: [Booster: Int] = [:]
    public var owned: Set<String> = []
    public var equipped: [CosmeticKind: String] = [:]
    public init() {}

    // MARK: Faucets
    public static func levelReward(stars: Int, dayStreak: Int, rewardedDouble: Bool, config: EconomyConfig) -> CoinReward {
        let base = (config.levelBaseCoins + config.coinsPerStar * max(0, min(stars, 3)))
            * (rewardedDouble ? config.rewardedCoinMultiplier : 1)
        let bonus = min(config.streakBonusCap, config.streakBonusPerDay * Double(max(0, dayStreak)))
        return CoinReward(base: base, streakBonus: Int((Double(base) * bonus).rounded()))
    }

    public mutating func earn(_ amount: Int) { coins += max(0, amount) }

    public mutating func grantBooster(_ b: Booster, count: Int = 1) { boosters[b, default: 0] += count }

    /// Grants for levels completed up to and including `level` that haven't been granted yet is the
    /// caller's job (tracked in SaveGame); this returns the grants due on first reaching `level`.
    public static func firstTimeGrants(atLevel level: Int, config: EconomyConfig) -> [Booster: Int] {
        config.boosterGrants[level] ?? [:]
    }

    // MARK: Sinks (cosmetics only; boosters are never purchasable — Play Promise)
    public mutating func buy(_ id: String) throws {
        guard let item = CosmeticCatalog.item(id) else { throw EconomyError.unknownItem }
        guard !owned.contains(id) else { throw EconomyError.alreadyOwned }
        guard coins >= item.price else { throw EconomyError.insufficientCoins }
        coins -= item.price
        owned.insert(id)
    }

    public mutating func equip(_ id: String) {
        guard owned.contains(id), let item = CosmeticCatalog.item(id) else { return }
        equipped[item.kind] = id
    }

    // MARK: Boosters
    public mutating func use(_ b: Booster) throws {
        guard (boosters[b] ?? 0) > 0 else { throw EconomyError.noBooster }
        boosters[b]! -= 1
    }
}
