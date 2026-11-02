import SpriteKit
import UIKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

/// Beveled Brick Breaker bricks: ink border, light top-left bevel, dark bottom-right bevel.
/// Cached per colour and size (design.md §1).
@MainActor
enum TextureFactory {
    private static var cache: [String: SKTexture] = [:]

    static func brick(_ color: BrickColor, size: CGFloat, cracked: Bool = false, gold: Bool = false) -> SKTexture {
        let key = "\(color.rawValue)-\(Int(size.rounded()))-\(cracked)-\(gold)"
        if let t = cache[key] { return t }
        let t = render(fill: Theme.brick(color), size: size, cracked: cracked, gold: gold)
        cache[key] = t
        return t
    }

    static func well(size: CGFloat) -> SKTexture {
        let key = "well-\(Int(size.rounded()))"
        if let t = cache[key] { return t }
        let t = image(size: size) { ctx, rect in
            Theme.hex(0x2A2145).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()
            UIColor.black.withAlphaComponent(0.4).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rect.width, height: 2))
        }
        cache[key] = t
        return t
    }

    static func gradient(size: CGSize) -> SKTexture {
        let r = UIGraphicsImageRenderer(size: size)
        let img = r.image { c in
            let cs = CGColorSpaceCreateDeviceRGB()
            let g = CGGradient(colorsSpace: cs, colors: [Theme.bgTop.cgColor, Theme.bgBottom.cgColor] as CFArray, locations: [0, 1])!
            c.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: img)
    }

    private static func render(fill: UIColor, size: CGFloat, cracked: Bool, gold: Bool) -> SKTexture {
        image(size: size) { ctx, rect in
            let b: CGFloat = max(2, size * 0.1)
            Theme.ink.setFill(); UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()
            let inner = rect.insetBy(dx: 2, dy: 2)
            fill.setFill(); ctx.fill(inner)
            UIColor.white.withAlphaComponent(0.35).setFill()
            ctx.fill(CGRect(x: inner.minX, y: inner.minY, width: inner.width, height: b))
            ctx.fill(CGRect(x: inner.minX, y: inner.minY, width: b, height: inner.height))
            UIColor.black.withAlphaComponent(0.25).setFill()
            ctx.fill(CGRect(x: inner.minX, y: inner.maxY - b, width: inner.width, height: b))
            ctx.fill(CGRect(x: inner.maxX - b, y: inner.minY, width: b, height: inner.height))
            if cracked {
                Theme.ink.setStroke()
                let p = UIBezierPath(); p.lineWidth = 2
                p.move(to: CGPoint(x: size * 0.3, y: 2)); p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.45))
                p.addLine(to: CGPoint(x: size * 0.4, y: size * 0.6)); p.addLine(to: CGPoint(x: size * 0.7, y: size - 2))
                p.stroke()
            }
            if gold {
                Theme.yellow.setFill(); Theme.ink.setStroke()
                let coin = UIBezierPath(ovalIn: rect.insetBy(dx: size * 0.28, dy: size * 0.28))
                coin.lineWidth = 2; coin.fill(); coin.stroke()
            }
        }
    }

    private static func image(size: CGFloat, draw: (CGContext, CGRect) -> Void) -> SKTexture {
        let s = CGSize(width: size, height: size)
        let img = UIGraphicsImageRenderer(size: s).image { draw($0.cgContext, CGRect(origin: .zero, size: s)) }
        let t = SKTexture(image: img)
        t.filteringMode = .nearest
        return t
    }
}
