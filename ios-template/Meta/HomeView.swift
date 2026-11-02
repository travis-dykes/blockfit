import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

struct HomeView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            BFBackground()
            VStack(spacing: 18) {
                HStack {
                    CoinChip(coins: app.save.wallet.coins)
                    Spacer()
                    Label("\(app.save.dayStreak.active(on: app.today))", systemImage: "flame.fill")
                        .font(.custom(Theme.fontName, size: Theme.FontSize.s)).foregroundStyle(Color.bf.yellow)
                        .accessibilityLabel("Day streak \(app.save.dayStreak.active(on: app.today))")
                }
                Spacer()
                BFText("BLOCK FIT", Theme.FontSize.xl, color: Color.bf.yellow)
                    .shadow(color: Color.bf.purple, radius: 0, x: 3, y: 3)
                Panel {
                    VStack(spacing: 10) {
                        BFText("LEVEL \(app.save.highestLevel)", Theme.FontSize.m, color: Color.bf.ink)
                        BFButton(title: "PLAY") { app.startLevel(app.save.highestLevel) }
                        BFButton(title: "LEVEL MAP", kind: .secondary) { app.route = .map }
                    }
                }
                modeTiles
                nextUnlock
                Spacer()
                HStack(spacing: 10) {
                    BFButton(title: "SHOP", kind: .secondary) { app.route = .shop }
                    BFButton(title: "SETTINGS", kind: .secondary) { app.route = .settings }
                }
            }.padding(20)
        }
    }

    private var modeTiles: some View {
        HStack(spacing: 10) {
            tile("CLASSIC", .classic) { app.startClassic() }
            tile("DAILY", .daily) { app.startDaily() }
            tile("TIME", .timeAttack) { }
        }
    }

    private func tile(_ name: String, _ mode: GameMode, action: @escaping () -> Void) -> some View {
        let unlocked = ModeGate.isUnlocked(mode, completedLevels: app.completedLevels) && mode != .timeAttack
        return Button(action: action) {
            VStack(spacing: 4) {
                BFText(name, color: Color.bf.ink)
                BFText(unlocked ? "PLAY" : (mode == .timeAttack && ModeGate.isUnlocked(mode, completedLevels: app.completedLevels) ? "SOON" : "L\(ModeGate.unlockLevel(mode))"),
                       color: unlocked ? Color.bf.green : Color.bf.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color.bf.cream, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bf.ink, lineWidth: 3))
            .opacity(unlocked ? 1 : 0.6)
        }
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "\(name) mode" : "\(name) locked until level \(ModeGate.unlockLevel(mode))")
    }

    /// "Comet Trail: 40 / 80" — every level visibly moves something.
    private var nextUnlock: some View {
        let next = CosmeticCatalog.all.first { !app.save.wallet.owned.contains($0.id) }
        return Group {
            if let n = next {
                VStack(alignment: .leading, spacing: 6) {
                    BFText("\(n.name.uppercased()): \(min(app.save.wallet.coins, n.price)) / \(n.price)")
                    ProgressView(value: Double(min(app.save.wallet.coins, n.price)), total: Double(n.price)).tint(Color.bf.yellow)
                }
            }
        }
    }
}
