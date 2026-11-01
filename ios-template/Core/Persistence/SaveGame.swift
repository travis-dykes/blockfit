import Foundation

/// Versioned save (CLAUDE.md rule 8). Bump `currentVersion` and add a migration + test
/// for any persisted shape change.
public struct SaveGame: Codable, Equatable, Sendable {
    public static let currentVersion = 2

    public var schemaVersion = SaveGame.currentVersion
    public var highestLevel = 1                     // next level to play
    public var stars: [Int: Int] = [:]
    public var wallet = Wallet()
    public var grantedAt: Set<Int> = []             // levels whose first-time booster grants were given
    public var classicBest = 0
    public var hints = HintSystem()
    public var dayStreak = DayStreak()
    public var dailyCompleted: Set<String> = []     // "yyyyMMdd"
    public var removeAds = false
    public var starterPackShown = false
    public var sessionIndex = 0
    public var settings = Settings()

    public struct Settings: Codable, Equatable, Sendable {
        public var sound = true, music = true, haptics = true, colorblind = false
        public init() {}
    }

    public init() {}
}

public enum SaveMigration {
    /// v1 stored `coins` at top level and had no day streak / settings.
    struct V1: Codable {
        var schemaVersion: Int
        var highestLevel: Int?
        var coins: Int?
        var classicBest: Int?
    }

    public static func decode(_ data: Data) throws -> SaveGame {
        let dec = JSONDecoder()
        let probe = try dec.decode(V1.self, from: data)
        switch probe.schemaVersion {
        case SaveGame.currentVersion:
            return try dec.decode(SaveGame.self, from: data)
        case 1:
            var s = SaveGame()
            s.highestLevel = probe.highestLevel ?? 1
            s.wallet.coins = probe.coins ?? 0
            s.classicBest = probe.classicBest ?? 0
            return s
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "unknown schema \(probe.schemaVersion)"))
        }
    }

    public static func encode(_ save: SaveGame) throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        return try enc.encode(save)
    }
}

public protocol SaveStore: Sendable {
    func load() -> SaveGame
    func save(_ game: SaveGame)
}

public final class InMemorySaveStore: SaveStore, @unchecked Sendable {
    private var game: SaveGame
    public init(_ game: SaveGame = SaveGame()) { self.game = game }
    public func load() -> SaveGame { game }
    public func save(_ game: SaveGame) { self.game = game }
}

public struct FileSaveStore: SaveStore {
    let url: URL
    public init(url: URL) { self.url = url }
    public func load() -> SaveGame {
        guard let d = try? Data(contentsOf: url), let g = try? SaveMigration.decode(d) else { return SaveGame() }
        return g
    }
    public func save(_ game: SaveGame) {
        if let d = try? SaveMigration.encode(game) { try? d.write(to: url, options: .atomic) }
    }
}
