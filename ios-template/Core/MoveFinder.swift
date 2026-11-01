/// The spot where a piece *almost* fit (for the "So close!" lose card).
public struct NearMiss: Equatable, Sendable {
    public var trayIndex: Int
    public var origin: GridPoint
    /// Empty board cells the piece would have covered.
    public var gapCells: [GridPoint]
    /// Filled board cells that blocked it.
    public var blockedCells: [GridPoint]
}

public enum MoveFinder {
    public static func hasAnyMove(tray: [Piece?], board: Board) -> Bool {
        tray.contains { p in p.map { board.canFitAnywhere($0) } ?? false }
    }

    /// Fewest blocked cells wins; ties prefer the larger gap, then the lowest row/col.
    public static func closestFit(tray: [Piece?], board: Board) -> NearMiss? {
        var best: NearMiss?
        for (i, slot) in tray.enumerated() {
            guard let piece = slot, piece.height <= board.size, piece.width <= board.size else { continue }
            for r in 0...(board.size - piece.height) {
                for c in 0...(board.size - piece.width) {
                    let origin = GridPoint(row: r, col: c)
                    var gap: [GridPoint] = [], blocked: [GridPoint] = []
                    for o in piece.offsets {
                        let p = GridPoint(row: r + o.row, col: c + o.col)
                        if board[p.row, p.col].isEmpty { gap.append(p) } else { blocked.append(p) }
                    }
                    guard !blocked.isEmpty else { continue }
                    let cand = NearMiss(trayIndex: i, origin: origin, gapCells: gap, blockedCells: blocked)
                    if let b = best {
                        if cand.blockedCells.count < b.blockedCells.count
                            || (cand.blockedCells.count == b.blockedCells.count && cand.gapCells.count > b.gapCells.count) {
                            best = cand
                        }
                    } else {
                        best = cand
                    }
                }
            }
        }
        return best
    }
}
