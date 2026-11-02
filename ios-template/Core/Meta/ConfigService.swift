import Foundation

/// Remote Config seam (BF-410). The Firebase-backed implementation lives in the app target;
/// overrides arrive as a flat JSON dictionary layered over bundled defaults.
public protocol ConfigService: Sendable {
    func gameConfig() -> GameConfig
    func economyConfig() -> EconomyConfig
}

public struct LocalConfigService: ConfigService {
    public var game = GameConfig.defaults
    public var economy = EconomyConfig()
    public init() {}
    public func gameConfig() -> GameConfig { game }
    public func economyConfig() -> EconomyConfig { economy }
}

public enum ConfigMerge {
    /// Deep-merges `overrides` (JSON object) onto `base`, returning the decoded result.
    public static func apply<T: Codable>(_ base: T, overrides: Data) -> T {
        guard let b = try? JSONEncoder().encode(base),
              var baseObj = (try? JSONSerialization.jsonObject(with: b)) as? [String: Any],
              let over = (try? JSONSerialization.jsonObject(with: overrides)) as? [String: Any] else { return base }
        baseObj = merge(baseObj, over)
        guard let merged = try? JSONSerialization.data(withJSONObject: baseObj),
              let out = try? JSONDecoder().decode(T.self, from: merged) else { return base }
        return out
    }

    static func merge(_ a: [String: Any], _ b: [String: Any]) -> [String: Any] {
        var out = a
        for (k, v) in b {
            if let av = out[k] as? [String: Any], let bv = v as? [String: Any] { out[k] = merge(av, bv) }
            else { out[k] = v }
        }
        return out
    }
}
