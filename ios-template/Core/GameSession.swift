public struct MoveOutcome: Equatable, Sendable {
    public var clear: ClearResult
    public var comet: ClearResult?
    public var cometPath: [GridPoint]
    public var score: MoveScore
    public var trayRefilled: Bool
    public var gameOver: Bool
    public var nearMiss: NearMiss?
    public var won = false
}

/// Classic (endless) rules. Gameplay reads this; it never owns rules.
public struct GameSession: Sendable {
    public private(set) var config: GameConfig
    public private(set) var board: Board
    public private(set) var tray: [Piece?] = []
    public private(set) var score = 0
    public private(set) var streak = 0
    public private(set) var maxCombo = 0
    public private(set) var linesTotal = 0
    public private(set) var traysDealt = 0
    public private(set) var isGameOver = false
    public private(set) var nearMiss: NearMiss?
    /// Levels mode only; nil in Classic.
    public let goal: LevelGoal?
    public private(set) var goldCollected = 0
    public private(set) var moves = 0
    public private(set) var isWon = false
    private var rng: SeededRNG
    private var undoSnapshot: Snapshot?

    private struct Snapshot: Sendable {
        var board: Board; var tray: [Piece?]; var score: Int; var streak: Int; var maxCombo: Int
        var linesTotal: Int; var goldCollected: Int; var moves: Int; var rng: SeededRNG; var traysDealt: Int
    }
    private let generator: TrayGenerator

    /// `initialTray` overrides the first dealt tray (debug setups, e.g. the Gate 0 capture).
    public init(seed: UInt64, config: GameConfig = .defaults, board: Board? = nil, initialTray: [Piece]? = nil,
                goal: LevelGoal? = nil) {
        self.goal = goal
        self.config = config
        self.board = board ?? Board(size: config.boardSize)
        self.rng = SeededRNG(seed: seed)
        self.generator = TrayGenerator(config: config)
        if let initialTray {
            tray = initialTray.map { Optional($0) }
            traysDealt = 1
        } else {
            dealTray()
        }
        if !MoveFinder.hasAnyMove(tray: tray, board: self.board) { isGameOver = true }
    }

    public mutating func setCometEnabled(_ on: Bool) { config.comet.enabled = on }

    private mutating func dealTray() {
        let guarantee = traysDealt < config.tray.classicGuaranteeTrays
        tray = generator.generate(board: board, rng: &rng, guarantee: guarantee).map { Optional($0) }
        traysDealt += 1
    }

    public func canPlace(slot: Int, at origin: GridPoint) -> Bool {
        guard !isGameOver, !isWon, tray.indices.contains(slot), let p = tray[slot] else { return false }
        return board.canPlace(p, at: origin)
    }

    @discardableResult
    public mutating func place(slot: Int, at origin: GridPoint) -> MoveOutcome? {
        guard canPlace(slot: slot, at: origin), let piece = tray[slot] else { return nil }
        let snapshot = Snapshot(board: board, tray: tray, score: score, streak: streak, maxCombo: maxCombo,
                                linesTotal: linesTotal, goldCollected: goldCollected, moves: moves,
                                rng: rng, traysDealt: traysDealt)
        board.place(piece, at: origin)
        tray[slot] = nil

        let clear = board.clear()
        var comet: ClearResult?
        var cometPath: [GridPoint] = []
        if CometClear.isTriggered(by: clear, config: config.comet) {
            cometPath = CometClear.path(after: clear, boardSize: board.size)
            comet = CometClear.apply(to: &board, path: cometPath, maxBricks: config.comet.maxBricks)
        }

        streak = clear.isEmpty ? 0 : streak + 1
        maxCombo = max(maxCombo, clear.lineCount)
        linesTotal += clear.lineCount
        let ms = Scoring.score(cellsPlaced: piece.cellCount, linesCleared: clear.lineCount, streak: streak,
                               boardEmptyAfter: board.isEmpty, config: config.scoring)
        score += ms.total

        moves += 1
        goldCollected += clear.goldCollected + (comet?.goldCollected ?? 0)
        if let goal, goal.progress(gold: goldCollected, score: score, lines: linesTotal) >= goal.target {
            isWon = true
        }

        undoSnapshot = snapshot
        var refilled = false
        if isWon {
            return MoveOutcome(clear: clear, comet: comet, cometPath: cometPath, score: ms,
                               trayRefilled: false, gameOver: false, nearMiss: nil, won: true)
        }
        if tray.allSatisfy({ $0 == nil }) { dealTray(); refilled = true; undoSnapshot = nil }   // undo never crosses a refill
        if !MoveFinder.hasAnyMove(tray: tray, board: board) {
            isGameOver = true
            nearMiss = MoveFinder.closestFit(tray: tray, board: board)
        }
        return MoveOutcome(clear: clear, comet: comet, cometPath: cometPath, score: ms,
                           trayRefilled: refilled, gameOver: isGameOver, nearMiss: nearMiss)
    }

    // MARK: Boosters (effects only; inventory/grants live in Economy)

    public var canUndo: Bool { undoSnapshot != nil && !isWon }

    /// Reverts the last placement (not across a tray refill).
    @discardableResult
    public mutating func undo() -> Bool {
        guard let s = undoSnapshot, !isWon else { return false }
        board = s.board; tray = s.tray; score = s.score; streak = s.streak; maxCombo = s.maxCombo
        linesTotal = s.linesTotal; goldCollected = s.goldCollected; moves = s.moves
        rng = s.rng; traysDealt = s.traysDealt
        isGameOver = false; nearMiss = nil; undoSnapshot = nil
        return true
    }

    /// Breaks one brick (the ball fires at it). Steel takes a hit. Returns nil if the cell is empty.
    @discardableResult
    public mutating func smash(at p: GridPoint) -> ClearResult? {
        guard !isWon, board.contains(p), !board[p.row, p.col].isEmpty else { return nil }
        var r = ClearResult()
        board.hit(p, into: &r)
        goldCollected += r.goldCollected
        undoSnapshot = nil
        if let goal, goal.progress(gold: goldCollected, score: score, lines: linesTotal) >= goal.target { isWon = true }
        refreshGameOver()
        return r
    }

    /// Swaps the current tray for three new pieces.
    @discardableResult
    public mutating func reroll() -> Bool {
        guard !isWon else { return false }
        dealTray_forced()
        undoSnapshot = nil
        isGameOver = false; nearMiss = nil
        refreshGameOver()
        return true
    }

    private mutating func dealTray_forced() { dealTray() }

    private mutating func refreshGameOver() {
        if !isWon, !MoveFinder.hasAnyMove(tray: tray, board: board) {
            isGameOver = true
            nearMiss = MoveFinder.closestFit(tray: tray, board: board)
        } else if !isWon {
            isGameOver = false; nearMiss = nil
        }
    }
}
