import Foundation

/// JSON level format (BF-120). Board rows are 8 strings of 8 chars:
/// `.` empty · `#` steel (2 hits) · `G` gold · r o y g b v p t s l c = brick colours.
public struct LevelData: Codable, Equatable, Sendable {
    public var id: Int
    public var goal: LevelGoal
    public var board: [String]
    /// Piece ids for the first tray; later trays are generated.
    public var tray: [String]?
    public var par: Int
    public var guaranteeTrays: Int = 10
    public var seed: UInt64 = 1

    public init(id: Int, goal: LevelGoal, board: [String], tray: [String]? = nil, par: Int,
                guaranteeTrays: Int = 10, seed: UInt64 = 1) {
        self.id = id; self.goal = goal; self.board = board; self.tray = tray
        self.par = par; self.guaranteeTrays = guaranteeTrays; self.seed = seed
    }
}

public enum LevelError: Error, Equatable {
    case badBoard, badCell(Character), unknownPiece(String)
}

public enum LevelLoader {
    static let colorKey: [Character: BrickColor] = [
        "r": .red, "o": .orange, "y": .yellow, "g": .green, "b": .blue, "v": .violet,
        "p": .pink, "t": .teal, "s": .sky, "l": .lime, "c": .cream,
    ]

    public static func decode(_ data: Data) throws -> LevelData {
        try JSONDecoder().decode(LevelData.self, from: data)
    }

    public static func makeBoard(_ level: LevelData, size: Int = 8) throws -> Board {
        guard level.board.count == size, level.board.allSatisfy({ $0.count == size }) else { throw LevelError.badBoard }
        var b = Board(size: size)
        for (r, row) in level.board.enumerated() {
            for (c, ch) in row.enumerated() {
                switch ch {
                case ".": break
                case "#": b[r, c] = .steel(hits: 2)
                case "G": b[r, c] = .gold
                default:
                    guard let col = colorKey[ch] else { throw LevelError.badCell(ch) }
                    b[r, c] = .brick(col)
                }
            }
        }
        return b
    }

    public static func makeSession(_ level: LevelData, config: GameConfig = .defaults) throws -> GameSession {
        var cfg = config
        cfg.tray.classicGuaranteeTrays = level.guaranteeTrays
        let board = try makeBoard(level, size: cfg.boardSize)
        var tray: [Piece]?
        if let ids = level.tray {
            tray = try ids.map { id in
                guard let p = PieceCatalog.piece(id: id) else { throw LevelError.unknownPiece(id) }
                return p
            }
        }
        return GameSession(seed: level.seed, config: cfg, board: board, initialTray: tray, goal: level.goal)
    }
}
