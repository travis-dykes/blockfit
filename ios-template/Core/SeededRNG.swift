/// SplitMix64. All randomness in Block Fit goes through this (CLAUDE.md rule 2).
public struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform double in [0, 1).
    public mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    /// Daily Puzzle seed: `yyyyMMdd` + salt.
    public static func dailySeed(year: Int, month: Int, day: Int, salt: UInt64 = 0) -> UInt64 {
        UInt64(year * 10_000 + month * 100 + day) &+ salt
    }
}
