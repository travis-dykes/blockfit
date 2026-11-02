import Foundation

/// Every tunable the Core reads (CLAUDE.md rule 4). Defaults mirror
/// `Config/Defaults.json`; Remote Config will override later (M4).
public struct GameConfig: Codable, Equatable, Sendable {
    public struct Scoring: Codable, Equatable, Sendable {
        public var cellPoints: Int = 1
        public var lineBase: Int = 10
        public var streakStep: Double = 0.5
        public var streakCap: Double = 3.0
        public var perfectClearBonus: Int = 300
        public init() {}
    }

    public struct Tray: Codable, Equatable, Sendable {
        public var size: Int = 3
        /// Classic: the first N trays must contain at least one placeable piece.
        public var classicGuaranteeTrays: Int = 3
        public init() {}
    }

    public struct Comet: Codable, Equatable, Sendable {
        public var enabled: Bool = false
        public var minLines: Int = 2
        public var maxBricks: Int = 3
        public init() {}
    }

    public var boardSize: Int = 8
    public var scoring = Scoring()
    public var tray = Tray()
    public var comet = Comet()
    /// Weight per piece *family*, split evenly across the family's orientations.
    public var pieceWeights: [String: Double] = [
        "dot": 4, "i2": 8, "i3": 8, "i4": 5, "i5": 3,
        "square2": 7, "square3": 2, "l3": 7, "l5": 3,
    ]

    public init() {}
    public static let defaults = GameConfig()
}
