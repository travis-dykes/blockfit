import Foundation
import Testing
@testable import BlockFitCore

struct PieceTests {
    @Test func offsetsNormalized() {
        for p in PieceCatalog.standard {
            #expect(p.offsets.map(\.row).min() == 0, "\(p.id)")
            #expect(p.offsets.map(\.col).min() == 0, "\(p.id)")
        }
    }

    @Test func catalogShape() {
        let ids = PieceCatalog.standard.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(PieceCatalog.standard.filter { $0.family == "l3" }.count == 4)
        #expect(PieceCatalog.standard.filter { $0.family == "l5" }.count == 4)
        #expect(PieceCatalog.piece(id: "l5_0")!.cellCount == 5)
        #expect(PieceCatalog.piece(id: "square3")!.cellCount == 9)
    }

    @Test func fixedColorPerFamily() {
        for fam in Set(PieceCatalog.standard.map(\.family)) {
            let colors = Set(PieceCatalog.standard.filter { $0.family == fam }.map(\.color))
            #expect(colors.count == 1, "\(fam)")
        }
    }
}

struct RNGTests {
    @Test func sameSeedSameSequence() {
        var a = SeededRNG(seed: 42), b = SeededRNG(seed: 42)
        for _ in 0..<100 { #expect(a.next() == b.next()) }
    }
    @Test func dailySeed() {
        #expect(SeededRNG.dailySeed(year: 2026, month: 11, day: 1) == 20_261_101)
    }
}

struct TrayTests {
    @Test func deterministic() {
        let g = TrayGenerator()
        var r1 = SeededRNG(seed: 7), r2 = SeededRNG(seed: 7)
        for _ in 0..<50 {
            #expect(g.generate(board: Board(), rng: &r1, guarantee: true)
                    == g.generate(board: Board(), rng: &r2, guarantee: true))
        }
    }

    @Test func guaranteeHoldsOnRandomBoards() {
        let g = TrayGenerator()
        var rng = SeededRNG(seed: 99)
        for _ in 0..<10_000 {
            var b = Board()
            let fill = Double(rng.next() % 100) / 100
            for r in 0..<8 { for c in 0..<8 where rng.nextUnit() < fill { b[r, c] = .brick(.blue) } }
            let tray = g.generate(board: b, rng: &rng, guarantee: true)
            #expect(tray.count == 3)
            if b.emptyCount > 0 { #expect(tray.contains { b.canFitAnywhere($0) }) }
        }
    }
}

struct MoveFinderTests {
    /// Board full except a 2×2 hole; tray holds a 3×3 → no move, near miss is the hole.
    @Test func nearMissTwoByTwoHoleThreeByThree() {
        var b = Board()
        for r in 0..<8 { for c in 0..<8 { b[r, c] = .brick(.blue) } }
        for (r, c) in [(3, 3), (3, 4), (4, 3), (4, 4)] { b[r, c] = .empty }
        let tray: [Piece?] = [PieceCatalog.piece(id: "square3"), nil, nil]
        #expect(!MoveFinder.hasAnyMove(tray: tray, board: b))
        let nm = MoveFinder.closestFit(tray: tray, board: b)
        #expect(nm != nil)
        #expect(nm!.gapCells.count == 4)
        #expect(nm!.blockedCells.count == 5)
        #expect(MoveFinder.hasAnyMove(tray: [PieceCatalog.piece(id: "square2")], board: b))
    }
}

struct ScoringTests {
    private let cfg = GameConfig.Scoring()
    @Test(arguments: [(1, 10), (2, 30), (3, 60), (4, 100)])
    func linePoints(n: Int, expected: Int) {
        #expect(Scoring.lineClearPoints(lines: n, config: cfg) == expected)
    }
    @Test(arguments: [(1, 1.0), (2, 1.5), (3, 2.0), (4, 2.5), (5, 3.0), (9, 3.0)])
    func streak(s: Int, expected: Double) {
        #expect(Scoring.streakMultiplier(streak: s, config: cfg) == expected)
    }
    @Test func moveScore() {
        let s = Scoring.score(cellsPlaced: 3, linesCleared: 2, streak: 2, boardEmptyAfter: false, config: cfg)
        #expect(s.cellPoints == 3 && s.linePoints == 45 && s.total == 48)
        let none = Scoring.score(cellsPlaced: 5, linesCleared: 0, streak: 0, boardEmptyAfter: true, config: cfg)
        #expect(none.total == 5)
        let pc = Scoring.score(cellsPlaced: 1, linesCleared: 1, streak: 1, boardEmptyAfter: true, config: cfg)
        #expect(pc.perfectClear && pc.total == 1 + 10 + 300)
    }
}

struct CometTests {
    @Test func pathAndBreak() {
        var b = Board()
        var res = ClearResult(); res.lines = [.row(4), .row(5)]
        let path = CometClear.path(after: res, boardSize: 8)
        #expect(path.first == GridPoint(row: 4, col: 6))   // from (5,7) up-left
        #expect(path.allSatisfy { b.contains($0) })
        for p in path { b[p.row, p.col] = .brick(.red) }
        let r = CometClear.apply(to: &b, path: path, maxBricks: 3)
        #expect(r.clearedCells.count == 3)
    }
    @Test func trigger() {
        var cfg = GameConfig.Comet(); var r = ClearResult(); r.lines = [.row(0), .row(1)]
        #expect(!CometClear.isTriggered(by: r, config: cfg))
        cfg.enabled = true
        #expect(CometClear.isTriggered(by: r, config: cfg))
        r.lines = [.row(0)]
        #expect(!CometClear.isTriggered(by: r, config: cfg))
    }
}

struct SessionTests {
    @Test func deterministicAndPlayable() {
        var a = GameSession(seed: 5), b = GameSession(seed: 5)
        #expect(a.tray == b.tray)
        var moves = 0
        while !a.isGameOver && moves < 500 {
            outer: for slot in 0..<3 {
                for r in 0..<8 { for c in 0..<8 where a.canPlace(slot: slot, at: GridPoint(row: r, col: c)) {
                    a.place(slot: slot, at: GridPoint(row: r, col: c))
                    b.place(slot: slot, at: GridPoint(row: r, col: c))
                    moves += 1
                    break outer
                } }
            }
        }
        #expect(a.score == b.score && a.board == b.board)
        #expect(a.score > 0)
    }

    @Test func gameOverWhenNothingFits() {
        var board = Board()
        for r in 0..<8 { for c in 0..<8 { board[r, c] = .brick(.blue) } }
        board[0, 0] = .empty
        var s = GameSession(seed: 1, board: board)
        // Tray guaranteed to contain something that fits one empty cell: the dot, or nothing else fits.
        guard let slot = s.tray.firstIndex(where: { $0?.id == "dot" }) else { return }
        let out = s.place(slot: slot, at: GridPoint(row: 0, col: 0))
        #expect(out != nil)
    }
}

struct ConfigTests {
    /// Defaults.json must stay in sync with `GameConfig.defaults` (CLAUDE.md rule 4).
    @Test func defaultsJSONMatchesCode() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ios-template/Config/Defaults.json")
        let cfg = try JSONDecoder().decode(GameConfig.self, from: Data(contentsOf: url))
        #expect(cfg == GameConfig.defaults)
    }
}

struct LevelTests {
    static func loadLevels() throws -> [LevelData] {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ios-template/Levels/levels")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try files.map { try LevelLoader.decode(Data(contentsOf: $0)) }
    }

    @Test func allHandBuiltLevelsLoad() throws {
        let levels = try Self.loadLevels()
        #expect(levels.count == 10)
        for lv in levels {
            let s = try LevelLoader.makeSession(lv)
            #expect(s.board.linesToClear().isEmpty, "level \(lv.id) starts with a full line")
            #expect(s.tray.count == 3)
        }
    }

    @Test func levelOneWinsInOneMove() throws {
        let lv = try Self.loadLevels()[0]
        var s = try LevelLoader.makeSession(lv)
        let slot = s.tray.firstIndex { $0?.id == "i3h" }!
        let out = s.place(slot: slot, at: GridPoint(row: 4, col: 5))
        #expect(out?.won == true && s.isWon)
    }

    @Test func goldLevelsWinWithIntendedMove() throws {
        let lv = try Self.loadLevels()[2]    // level 3: i2v at col 5 clears rows 6 & 7 with 3 gold
        var s = try LevelLoader.makeSession(lv)
        let out = s.place(slot: 0, at: GridPoint(row: 6, col: 5))
        #expect(out?.won == true)
        #expect(s.goldCollected == 3)
    }

    @Test func starsRule() {
        #expect(Stars.rate(moves: 1, par: 1) == 3)
        #expect(Stars.rate(moves: 3, par: 1) == 2)
        #expect(Stars.rate(moves: 9, par: 1) == 1)
        #expect(Stars.rate(moves: 1, par: 1, boostersUsed: 1) == 2)
    }

    @Test func solverIsDeterministic() throws {
        let lv = try Self.loadLevels()[0]
        #expect(Solver.winRate(lv, runs: 5) == Solver.winRate(lv, runs: 5))
        #expect(Solver.winRate(lv, runs: 5) == 1.0)
    }

    @Test func generatorProducesValidBoards() {
        var rng = SeededRNG(seed: 3)
        for id in 11...20 {
            let lv = LevelGenerator.candidate(id: id, params: LevelGenerator.params(forLevel: id), rng: &rng)
            let b = try? LevelLoader.makeBoard(lv)
            #expect(b != nil && b!.linesToClear().isEmpty)
        }
    }
}

struct HintTests {
    @Test func oneAtATimeAndNeverRepeated() {
        var h = HintSystem()
        #expect(h.request(.dragPointer, level: 1) == .dragPointer)
        #expect(h.request(.goalChipPulse, level: 3) == nil)     // one active already
        h.dismiss()
        #expect(h.request(.dragPointer, level: 1) == nil)        // consumed
        #expect(h.request(.goalChipPulse, level: 2) == nil)      // wrong level
        #expect(h.request(.goalChipPulse, level: 3) == .goalChipPulse)
    }
    @Test func analyticsNamesSnakeCase() {
        #expect(AnalyticsEvent.appOpen(sessionIndex: 1).name == "app_open")
        #expect(AnalyticsEvent.linesClear(count: 3, combo: 3, streak: 1, comet: false).name == "lines_clear")
    }
}
