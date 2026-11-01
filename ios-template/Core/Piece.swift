public struct Piece: Hashable, Sendable {
    public let id: String
    public let family: String
    public let color: BrickColor
    /// Normalized: min row == 0 and min col == 0.
    public let offsets: [GridPoint]

    public var height: Int { (offsets.map(\.row).max() ?? 0) + 1 }
    public var width: Int { (offsets.map(\.col).max() ?? 0) + 1 }
    public var cellCount: Int { offsets.count }

    public init(id: String, family: String, color: BrickColor, offsets: [GridPoint]) {
        self.id = id
        self.family = family
        self.color = color
        self.offsets = Piece.normalize(offsets)
    }

    static func normalize(_ pts: [GridPoint]) -> [GridPoint] {
        let r = pts.map(\.row).min() ?? 0
        let c = pts.map(\.col).min() ?? 0
        return pts.map { GridPoint(row: $0.row - r, col: $0.col - c) }.sorted()
    }

    func rotatedClockwise() -> [GridPoint] {
        offsets.map { GridPoint(row: $0.col, col: -$0.row) }
    }
}

/// v1 piece set: 1×1, 1×2…1×5 (both orientations), 2×2, 3×3, small L, big L.
/// T and S/Z are held back as a later difficulty lever.
public enum PieceCatalog {
    public static let standard: [Piece] = build()

    public static func piece(id: String) -> Piece? { standard.first { $0.id == id } }

    /// Per-piece weight: family weight split evenly across that family's members.
    public static func weights(config: GameConfig, pieces: [Piece] = standard) -> [Double] {
        pieces.map { p in
            let members = pieces.filter { $0.family == p.family }.count
            return (config.pieceWeights[p.family] ?? 0) / Double(max(members, 1))
        }
    }

    private static func parse(_ rows: [String]) -> [GridPoint] {
        var out: [GridPoint] = []
        for (r, line) in rows.enumerated() {
            for (c, ch) in line.enumerated() where ch == "X" { out.append(GridPoint(row: r, col: c)) }
        }
        return out
    }

    private static func line(_ n: Int, horizontal: Bool) -> [GridPoint] {
        (0..<n).map { horizontal ? GridPoint(row: 0, col: $0) : GridPoint(row: $0, col: 0) }
    }

    private static func build() -> [Piece] {
        var out: [Piece] = []
        out.append(Piece(id: "dot", family: "dot", color: .cream, offsets: [GridPoint(row: 0, col: 0)]))
        let lineColors: [Int: BrickColor] = [2: .sky, 3: .blue, 4: .green, 5: .red]
        for n in 2...5 {
            let color = lineColors[n] ?? .blue
            out.append(Piece(id: "i\(n)h", family: "i\(n)", color: color, offsets: line(n, horizontal: true)))
            out.append(Piece(id: "i\(n)v", family: "i\(n)", color: color, offsets: line(n, horizontal: false)))
        }
        out.append(Piece(id: "square2", family: "square2", color: .yellow, offsets: parse(["XX", "XX"])))
        out.append(Piece(id: "square3", family: "square3", color: .violet, offsets: parse(["XXX", "XXX", "XXX"])))
        out += rotations(family: "l3", color: .teal, base: parse(["X.", "XX"]))
        out += rotations(family: "l5", color: .orange, base: parse(["X..", "X..", "XXX"]))
        return out
    }

    private static func rotations(family: String, color: BrickColor, base: [GridPoint]) -> [Piece] {
        var seen = Set<[GridPoint]>()
        var out: [Piece] = []
        var current = Piece(id: "tmp", family: family, color: color, offsets: base)
        for i in 0..<4 {
            if seen.insert(current.offsets).inserted {
                out.append(Piece(id: "\(family)_\(i)", family: family, color: color, offsets: current.offsets))
            }
            current = Piece(id: "tmp", family: family, color: color, offsets: current.rotatedClockwise())
        }
        return out
    }
}
