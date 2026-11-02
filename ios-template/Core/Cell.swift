public struct GridPoint: Hashable, Comparable, Sendable {
    public var row: Int
    public var col: Int
    public init(row: Int, col: Int) { self.row = row; self.col = col }
    public static func < (a: GridPoint, b: GridPoint) -> Bool {
        a.row != b.row ? a.row < b.row : a.col < b.col
    }
}

/// Palette names only; hex values live in `Theme` (CLAUDE.md rule 5).
public enum BrickColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, blue, violet, pink, teal, steel, sky, lime, cream
}

public enum Cell: Equatable, Sendable {
    case empty
    case brick(BrickColor)
    /// `hits` = clears still needed to shatter it (2 = fresh, 1 = cracked).
    case steel(hits: Int)
    case gold

    public var isEmpty: Bool { self == .empty }
}
