/// Greedy bot (BF-140): plays a level with a one-ply heuristic. Used to validate
/// generated levels and to answer "is this beatable without boosters?" (Play Promise).
public enum Solver {
    public struct Result: Equatable, Sendable {
        public var won: Bool
        public var moves: Int
    }

    static func heuristic(before: GameSession, after: GameSession, out: MoveOutcome) -> Double {
        var h = Double(out.clear.lineCount) * 100 + Double(out.clear.goldCollected) * 60
        h += Double(out.score.total) * 0.5
        h -= Double(after.board.emptyCount == 0 ? 1000 : 0)
        h += Double(after.board.emptyCount) * 0.3      // prefer open boards
        return h
    }

    public static func play(_ start: GameSession, maxMoves: Int = 200, rng: inout SeededRNG) -> Result {
        var s = start
        var n = 0
        while !s.isGameOver, !s.isWon, n < maxMoves {
            var best: (slot: Int, at: GridPoint, score: Double)?
            for slot in s.tray.indices {
                guard let piece = s.tray[slot] else { continue }
                for at in s.board.positions(for: piece) {
                    var copy = s
                    guard let out = copy.place(slot: slot, at: at) else { continue }
                    let h = heuristic(before: s, after: copy, out: out) + rng.nextUnit() * 0.01  // seeded tie-break
                    if best == nil || h > best!.score { best = (slot, at, h) }
                }
            }
            guard let b = best else { break }
            s.place(slot: b.slot, at: b.at)
            n += 1
        }
        return Result(won: s.isWon, moves: n)
    }

    public static func winRate(_ level: LevelData, runs: Int, seed: UInt64 = 1,
                               config: GameConfig = .defaults) -> Double {
        guard runs > 0, let base = try? LevelLoader.makeSession(level, config: config) else { return 0 }
        var wins = 0
        var rng = SeededRNG(seed: seed)
        for i in 0..<runs {
            var lv = level
            lv.seed = level.seed &+ UInt64(i)       // varies later trays only
            guard let s = try? LevelLoader.makeSession(lv, config: config) else { continue }
            _ = base
            if play(s, rng: &rng).won { wins += 1 }
        }
        return Double(wins) / Double(runs)
    }
}
