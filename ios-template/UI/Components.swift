import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

extension Color {
    init(_ ui: UIColor) { self.init(uiColor: ui) }
    static let bf = (
        ink: Color(Theme.ink), cream: Color(Theme.cream), purple: Color(Theme.purple), yellow: Color(Theme.yellow),
        well: Color(Theme.boardWell), muted: Color(Theme.mutedInk), green: Color(Theme.green), blue: Color(Theme.blue)
    )
}

struct BFBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(Theme.bgTop), Color(Theme.bgBottom)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
    }
}

/// Chunky button (primary = yellow CTA, secondary = purple).
struct BFButton: View {
    enum Kind { case primary, secondary }
    var title: String; var kind: Kind = .primary; var disabled = false; var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.custom(Theme.fontName, size: Theme.FontSize.m))
                .foregroundStyle(kind == .primary ? Color.bf.ink : .white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(kind == .primary ? Color.bf.yellow : Color.bf.purple, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bf.ink, lineWidth: 3))
                .opacity(disabled ? 0.45 : 1)
        }
        .disabled(disabled)
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).background(Color.bf.cream, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bf.ink, lineWidth: 4))
            .foregroundStyle(Color.bf.ink)
    }
}

struct BFText: View {
    var text: String; var size: CGFloat = Theme.FontSize.s; var color: Color = .white
    init(_ t: String, _ size: CGFloat = Theme.FontSize.s, color: Color = .white) { text = t; self.size = size; self.color = color }
    var body: some View { Text(text).font(.custom(Theme.fontName, size: size)).foregroundStyle(color) }
}

struct StarsRow: View {
    var count: Int
    var body: some View {
        HStack(spacing: 6) { ForEach(0..<3, id: \.self) { i in
            Image(systemName: i < count ? "star.fill" : "star").foregroundStyle(i < count ? Color.bf.yellow : Color.bf.muted)
        } }.accessibilityLabel("\(count) of 3 stars")
    }
}

struct CoinChip: View {
    var coins: Int
    var body: some View {
        HStack(spacing: 6) { Circle().fill(Color.bf.yellow).frame(width: 14, height: 14).overlay(Circle().stroke(Color.bf.ink, lineWidth: 2))
            BFText("\(coins)", color: Color.bf.ink) }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.bf.cream, in: Capsule()).overlay(Capsule().stroke(Color.bf.ink, lineWidth: 2))
            .accessibilityLabel("\(coins) coins")
    }
}
