import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

struct MapView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            BFBackground()
            VStack {
                HStack {
                    Button("Back") { app.route = .home }.foregroundStyle(.white)
                    Spacer(); CoinChip(coins: app.save.wallet.coins)
                }.padding()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach((1...max(30, app.save.highestLevel + 10)).reversed(), id: \.self) { n in node(n) }
                    }.padding()
                }
            }
        }
    }

    @ViewBuilder private func node(_ n: Int) -> some View {
        let unlocked = n <= app.save.highestLevel
        VStack(spacing: 4) {
            Button { app.startLevel(n) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(unlocked ? Color.bf.yellow : Color.bf.purple.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bf.ink, lineWidth: 3))
                    BFText("\(n)", Theme.FontSize.m, color: Color.bf.ink)
                }.frame(width: 72, height: 72)
            }
            .disabled(!unlocked)
            .accessibilityLabel(unlocked ? "Level \(n), \(app.save.stars[n] ?? 0) stars" : "Level \(n) locked")
            if let s = app.save.stars[n] { StarsRow(count: s) }
            if LevelMap.hasChest(afterLevel: n, config: app.economy) {
                BFText("CHEST +\(app.economy.chestCoins)", color: Color.bf.yellow)
            }
        }
        .offset(x: CGFloat((n % 4) - 2) * 28)
    }
}
