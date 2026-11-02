import SpriteKit
import SwiftUI
import UIKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

/// Single home for hex values (CLAUDE.md rule 5). Mirrors Brick Breaker tokens, design.md §1.
enum Theme {
    static func hex(_ v: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255, alpha: alpha)
    }

    static let bgTop = hex(0x221A37)
    static let bgBottom = hex(0x3A2A5E)
    static let ink = hex(0x1F2340)
    static let cream = hex(0xF8EFD8)
    static let purple = hex(0x8E7FB5)
    static let yellow = hex(0xF2C72B)
    static let blue = hex(0x2B9BDB)
    static let green = hex(0x3DB54A)
    static let boardWell = hex(0x1A1430)
    static let mutedInk = hex(0x8A7F9E)
    static let invalid = hex(0xE03A3A)

    static func brick(_ c: BrickColor) -> UIColor {
        switch c {
        case .red: return hex(0xE03A3A)
        case .orange: return hex(0xF08A24)
        case .yellow: return hex(0xF2C72B)
        case .green: return hex(0x3DB54A)
        case .blue: return hex(0x2B9BDB)
        case .violet: return hex(0x8A4AD6)
        case .pink: return hex(0xE85DAA)
        case .teal: return hex(0x1FA58A)
        case .steel: return hex(0x9AA0A8)
        case .sky: return hex(0x6FD8EE)
        case .lime: return hex(0xA6D93A)
        case .cream: return hex(0xF8EFD8)
        }
    }

    // Departure Mono is bundled in M1; until then fall back to system mono.
    static let fontName = "Menlo-Bold"
    /// Departure Mono sizes snap to 11 / 22 / 33 / 44.
    enum FontSize { static let s: CGFloat = 11, m: CGFloat = 22, l: CGFloat = 33, xl: CGFloat = 44 }
}
