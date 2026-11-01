public struct TrayGenerator: Sendable {
    public let config: GameConfig
    public let pieces: [Piece]
    private let weights: [Double]

    public init(config: GameConfig = .defaults, pieces: [Piece] = PieceCatalog.standard) {
        self.config = config
        self.pieces = pieces
        self.weights = PieceCatalog.weights(config: config, pieces: pieces)
    }

    /// Draws `config.tray.size` pieces. With `guarantee`, at least one piece fits
    /// the board whenever any piece could possibly fit.
    public func generate(board: Board, rng: inout SeededRNG, guarantee: Bool) -> [Piece] {
        var tray = (0..<config.tray.size).map { _ in draw(from: Array(pieces.indices), rng: &rng) }
        guard guarantee, !tray.contains(where: { board.canFitAnywhere($0) }) else { return tray }
        let fitting = pieces.indices.filter { board.canFitAnywhere(pieces[$0]) }
        guard !fitting.isEmpty else { return tray }
        let slot = Int(rng.next() % UInt64(tray.count))
        tray[slot] = draw(from: fitting, rng: &rng)
        return tray
    }

    private func draw(from indices: [Int], rng: inout SeededRNG) -> Piece {
        let total = indices.reduce(0.0) { $0 + weights[$1] }
        guard total > 0 else { return pieces[indices[Int(rng.next() % UInt64(indices.count))]] }
        var roll = rng.nextUnit() * total
        for i in indices {
            roll -= weights[i]
            if roll < 0 { return pieces[i] }
        }
        return pieces[indices[indices.count - 1]]
    }
}
