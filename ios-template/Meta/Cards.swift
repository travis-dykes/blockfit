import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

/// Result cards. Copy is honest: no timers, no guilt, equal-weight "No thanks".
struct WinCard: View {
    @EnvironmentObject var app: AppState
    var info: WinInfo
    var body: some View {
        Panel {
            VStack(spacing: 12) {
                BFText(info.level == 0 ? "DAILY DONE" : "LEVEL \(info.level) CLEAR", Theme.FontSize.m, color: Color.bf.ink)
                StarsRow(count: info.stars)
                BFText("+\(info.reward.total) COINS", color: Color.bf.ink)
                ForEach(info.newModes, id: \.self) { BFText("\($0.rawValue.uppercased()) UNLOCKED", color: Color.bf.green) }
                BFButton(title: "COLLECT") { app.collect(info) }
                BFButton(title: "2x COINS ▶", kind: .secondary) { app.collectDouble(info) }
                if info.level > 0 { BFButton(title: "NEXT LEVEL", kind: .secondary) { app.nextLevel(after: info) } }
            }
        }.padding(24)
    }
}

struct LoseCard: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Panel {
            VStack(spacing: 12) {
                BFText("SO CLOSE!", Theme.FontSize.m, color: Color.bf.ink)
                BFText("No piece fits. Try again?", color: Color.bf.ink)
                if app.canContinue { BFButton(title: "CONTINUE ▶ (NEW TRAY)") { app.continueAfterFail() } }
                BFButton(title: "RETRY", kind: .secondary) { app.retry() }
                BFButton(title: "HOME", kind: .secondary) { app.goHome() }
            }
        }.padding(24)
    }
}

struct ClassicOverCard: View {
    @EnvironmentObject var app: AppState
    var score: Int; var best: Int
    var body: some View {
        Panel {
            VStack(spacing: 12) {
                BFText(score >= best && score > 0 ? "NEW BEST!" : "GAME OVER", Theme.FontSize.m, color: Color.bf.ink)
                BFText("SCORE \(score)  BEST \(best)", color: Color.bf.ink)
                BFButton(title: "PLAY AGAIN") { app.startClassic() }
                BFButton(title: "HOME", kind: .secondary) { app.goHome() }
            }
        }.padding(24)
    }
}

/// Single calm card, clear price, equal-weight "No thanks".
struct StarterPackCard: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Panel {
            VStack(spacing: 12) {
                BFText("STARTER PACK", Theme.FontSize.m, color: Color.bf.ink)
                BFText("Remove Ads + Neon theme + 300 coins", color: Color.bf.ink)
                BFButton(title: "GET IT — $2.99") { app.purchase(.starterPack, placement: "starter_pack") }
                BFButton(title: "NO THANKS", kind: .secondary) { app.overlay = .none; app.route = .map }
            }
        }.padding(24)
    }
}
