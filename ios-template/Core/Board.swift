public enum Line: Hashable, Sendable {
    case row(Int)
    case col(Int)
}

public struct ClearResult: Equatable, Sendable {
    /// Cleared lines in resolve order: rows (top→bottom) then columns (left→right).
    public var lines: [Line] = []
    public var rows: [Int] {
        lines.compactMap { line -> Int? in
            if case .row(let r) = line { return r }
            return nil
        }
    }
    public var cols: [Int] {
        lines.compactMap { line -> Int? in
            if case .col(let c) = line { return c }
            return nil
        }
    }
    /// Cells removed from the board (bricks, shattered steel, collected gold). Each cell once.
    public var clearedCells: [GridPoint] = []
    public var goldCollected = 0
    /// Steel cells that took a first hit and stay on the board.
    public var steelCracked: [GridPoint] = []
    public var steelBroken: [GridPoint] = []
    public var lineCount: Int { lines.count }
    public var isEmpty: Bool { lines.isEmpty }
}

public struct Board: Equatable, Sendable {
    public let size: Int
    public private(set) var cells: [[Cell]]

    public init(size: Int = 8) {
        self.size = size
        cells = Array(repeating: Array(repeating: .empty, count: size), count: size)
    }

    public subscript(row: Int, col: Int) -> Cell {
        get { cells[row][col] }
        set { cells[row][col] = newValue }
    }

    public func contains(_ p: GridPoint) -> Bool {
        p.row >= 0 && p.row < size && p.col >= 0 && p.col < size
    }

    public var isEmpty: Bool { cells.allSatisfy { $0.allSatisfy(\.isEmpty) } }
    public var emptyCount: Int { cells.reduce(0) { $0 + $1.filter(\.isEmpty).count } }

    public func canPlace(_ piece: Piece, at origin: GridPoint) -> Bool {
        piece.offsets.allSatisfy { o in
            let p = GridPoint(row: origin.row + o.row, col: origin.col + o.col)
            return contains(p) && cells[p.row][p.col].isEmpty
        }
    }

    /// Returns false (and changes nothing) if the placement is illegal.
    @discardableResult
    public mutating func place(_ piece: Piece, at origin: GridPoint) -> Bool {
        guard canPlace(piece, at: origin) else { return false }
        for o in piece.offsets {
            cells[origin.row + o.row][origin.col + o.col] = .brick(piece.color)
        }
        return true
    }

    /// Full lines. A line is full when no cell is empty (steel and gold count as filled).
    public func linesToClear() -> [Line] {
        var out: [Line] = []
        for r in 0..<size where cells[r].allSatisfy({ !$0.isEmpty }) { out.append(.row(r)) }
        for c in 0..<size where (0..<size).allSatisfy({ !cells[$0][c].isEmpty }) { out.append(.col(c)) }
        return out
    }

    /// Clears all full lines at once. Intersection cells are processed once.
    @discardableResult
    public mutating func clear() -> ClearResult {
        let lines = linesToClear()
        var result = ClearResult()
        result.lines = lines
        var targets = Set<GridPoint>()
        for line in lines {
            for i in 0..<size {
                switch line {
                case .row(let r): targets.insert(GridPoint(row: r, col: i))
                case .col(let c): targets.insert(GridPoint(row: i, col: c))
                }
            }
        }
        for p in targets.sorted() { hit(p, into: &result) }
        return result
    }

    /// Applies one clear-hit to a cell (used by line clears, Comet Clear and Smash).
    public mutating func hit(_ p: GridPoint, into result: inout ClearResult) {
        switch cells[p.row][p.col] {
        case .empty:
            break
        case .brick:
            cells[p.row][p.col] = .empty
            result.clearedCells.append(p)
        case .gold:
            cells[p.row][p.col] = .empty
            result.clearedCells.append(p)
            result.goldCollected += 1
        case .steel(let hits):
            if hits > 1 {
                cells[p.row][p.col] = .steel(hits: hits - 1)
                result.steelCracked.append(p)
            } else {
                cells[p.row][p.col] = .empty
                result.clearedCells.append(p)
                result.steelBroken.append(p)
            }
        }
    }

    // MARK: Fit queries

    public func positions(for piece: Piece) -> [GridPoint] {
        var out: [GridPoint] = []
        guard piece.height <= size, piece.width <= size else { return out }
        for r in 0...(size - piece.height) {
            for c in 0...(size - piece.width) {
                let o = GridPoint(row: r, col: c)
                if canPlace(piece, at: o) { out.append(o) }
            }
        }
        return out
    }

    public func canFitAnywhere(_ piece: Piece) -> Bool {
        guard piece.height <= size, piece.width <= size else { return false }
        for r in 0...(size - piece.height) {
            for c in 0...(size - piece.width) where canPlace(piece, at: GridPoint(row: r, col: c)) { return true }
        }
        return false
    }
}
