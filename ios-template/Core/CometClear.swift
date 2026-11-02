/// Comet Clear (M0 experiment, debug-toggled). After a clear of 2+ lines the ball
/// keeps going from the end of the last line along a diagonal heading toward the
/// board centre, breaking up to `maxBricks` filled cells.
public enum CometClear {
    public static func isTriggered(by result: ClearResult, config: GameConfig.Comet) -> Bool {
        config.enabled && result.lineCount >= config.minLines
    }

    /// Every in-bounds cell on the diagonal, in travel order (previewable).
    public static func path(after result: ClearResult, boardSize: Int) -> [GridPoint] {
        guard let last = result.lines.last else { return [] }
        let start: GridPoint
        switch last {
        case .row(let r): start = GridPoint(row: r, col: boardSize - 1)
        case .col(let c): start = GridPoint(row: 0, col: c)
        }
        let mid = boardSize / 2
        let dr = start.row >= mid ? -1 : 1
        let dc = start.col >= mid ? -1 : 1
        var out: [GridPoint] = []
        var p = GridPoint(row: start.row + dr, col: start.col + dc)
        while p.row >= 0, p.row < boardSize, p.col >= 0, p.col < boardSize {
            out.append(p)
            p = GridPoint(row: p.row + dr, col: p.col + dc)
        }
        return out
    }

    /// Hits up to `maxBricks` filled cells along the path. Call on the post-clear board.
    public static func apply(to board: inout Board, path: [GridPoint], maxBricks: Int) -> ClearResult {
        var result = ClearResult()
        var broken = 0
        for p in path where broken < maxBricks && !board[p.row, p.col].isEmpty {
            board.hit(p, into: &result)
            broken += 1
        }
        return result
    }
}
