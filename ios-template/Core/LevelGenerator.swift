/// Param-table level generator (BF-140). Levels 11+ come from here, then get
/// accepted only if the solver's win rate falls in the target band.
public struct LevelParams: Codable, Equatable, Sendable {
    public var fillRatio: Double
    public var goalCount: Int
    public var steelRatio: Double
    public var trayGuarantee: Int
    public var par: Int
    public init(fillRatio: Double, goalCount: Int, steelRatio: Double, trayGuarantee: Int, par: Int) {
        self.fillRatio = fillRatio; self.goalCount = goalCount; self.steelRatio = steelRatio
        self.trayGuarantee = trayGuarantee; self.par = par
    }
}

public enum LevelGenerator {
    public static let winRateBand = 0.35...0.95

    /// Param ramp for level ids ≥ 11.
    public static func params(forLevel id: Int) -> LevelParams {
        let t = Double(min(max(id - 11, 0), 60)) / 60
        return LevelParams(fillRatio: 0.30 + 0.20 * t,
                           goalCount: 4 + Int(t * 6),
                           steelRatio: 0.05 + 0.15 * t,
                           trayGuarantee: id <= 20 ? 6 : 3,
                           par: 5 + Int(t * 5))
    }

    /// One unvalidated candidate. No full lines are produced.
    public static func candidate(id: Int, params p: LevelParams, rng: inout SeededRNG) -> LevelData {
        let colors = Array(LevelLoader.colorKey.keys.sorted())
        var grid = Array(repeating: Array(repeating: Character("."), count: 8), count: 8)
        for r in 0..<8 { for c in 0..<8 where rng.nextUnit() < p.fillRatio {
            grid[r][c] = rng.nextUnit() < p.steelRatio ? "#" : colors[Int(rng.next() % UInt64(colors.count))]
        } }
        for r in 0..<8 where !grid[r].contains(".") { grid[r][Int(rng.next() % 8)] = "." }
        for c in 0..<8 where !(0..<8).contains(where: { grid[$0][c] == "." }) { grid[Int(rng.next() % 8)][c] = "." }
        var placed = 0, guardCount = 0
        while placed < p.goalCount, guardCount < 500 {
            guardCount += 1
            let r = Int(rng.next() % 8), c = Int(rng.next() % 8)
            if grid[r][c] != "G" { grid[r][c] = "G"; placed += 1 }
        }
        for r in 0..<8 where !grid[r].contains(".") { grid[r][Int(rng.next() % 8)] = "." }
        for c in 0..<8 where !(0..<8).contains(where: { grid[$0][c] == "." }) { grid[Int(rng.next() % 8)][c] = "." }
        let board = grid.map { String($0) }
        return LevelData(id: id, goal: .collectGold(placed), board: board, tray: nil, par: p.par,
                         guaranteeTrays: p.trayGuarantee, seed: rng.next() | 1)
    }

    /// Tries up to `attempts` candidates; nil if none lands in the band.
    public static func generate(id: Int, baseSeed: UInt64 = 0xB10C, attempts: Int = 40, runs: Int = 30) -> LevelData? {
        var rng = SeededRNG(seed: baseSeed &+ UInt64(id))
        let p = params(forLevel: id)
        for _ in 0..<attempts {
            let lv = candidate(id: id, params: p, rng: &rng)
            if winRateBand.contains(Solver.winRate(lv, runs: runs)) { return lv }
        }
        return nil
    }
}
