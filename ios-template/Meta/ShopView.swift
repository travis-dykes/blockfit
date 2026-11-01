import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

struct ShopView: View {
    enum Tab: String, CaseIterable { case themes = "Themes", trails = "Trails", boards = "Boards", items = "Items", coins = "Coins" }
    @EnvironmentObject var app: AppState
    @State private var tab: Tab = .themes

    var body: some View {
        ZStack {
            BFBackground()
            VStack(spacing: 12) {
                HStack { Button("Back") { app.route = .home }.foregroundStyle(.white); Spacer(); CoinChip(coins: app.save.wallet.coins) }
                Picker("Tab", selection: $tab) { ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                ScrollView { VStack(spacing: 10) { content } }
            }.padding()
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .themes: cosmetics(.theme)
        case .trails: cosmetics(.trail)
        case .boards: cosmetics(.board)
        case .items: items
        case .coins: coins
        }
    }

    private func cosmetics(_ kind: CosmeticKind) -> some View {
        ForEach(CosmeticCatalog.all.filter { $0.kind == kind }) { c in
            Panel {
                HStack {
                    BFText(c.name.uppercased(), Theme.FontSize.m, color: Color.bf.ink)
                    Spacer()
                    if app.save.wallet.owned.contains(c.id) {
                        let on = app.save.wallet.equipped[c.kind] == c.id
                        Button(on ? "EQUIPPED" : "EQUIP") { app.save.wallet.equip(c.id) }.disabled(on)
                    } else {
                        Button("\(c.price) COINS") { app.buy(c.id) }.disabled(app.save.wallet.coins < c.price)
                    }
                }
            }
        }
    }

    /// Booster *inventory* (never a store): counts, plus watch-for-+1 and one free daily.
    private var items: some View {
        VStack(spacing: 10) {
            ForEach(Booster.allCases, id: \.self) { b in
                Panel {
                    HStack {
                        BFText("\(b.rawValue.uppercased()) x\(app.save.wallet.boosters[b] ?? 0)", Theme.FontSize.m, color: Color.bf.ink)
                        Spacer()
                        Button("WATCH FOR +1") { app.watchForBooster(b) }
                    }
                }
            }
            BFText("Boosters are earned or watched for. They are never for sale.", color: Color.bf.muted)
            if app.dailyFreeBoosterAvailable {
                BFButton(title: "FREE DAILY BOOSTER ▶", kind: .secondary) { app.claimDailyFreeBooster(.undo) }
            }
        }
    }

    private var coins: some View {
        VStack(spacing: 10) {
            ForEach([SKU.coinsS, .coinsM, .coinsL], id: \.self) { sku in
                BFButton(title: "\(label(sku)) — $\(String(format: "%.2f", Double(sku.startingPriceCents) / 100))", kind: .secondary) {
                    app.purchase(sku, placement: "shop")
                }
            }
            BFText("Coins buy cosmetics only.", color: Color.bf.muted)
            if !app.save.removeAds {
                BFButton(title: "REMOVE ADS — $3.99") { app.purchase(.removeAds, placement: "shop") }
            }
            BFButton(title: "RESTORE PURCHASES", kind: .secondary) { app.restorePurchases() }
        }
    }

    private func label(_ sku: SKU) -> String {
        let e = app.economy
        switch sku { case .coinsS: return "\(e.coinPackSmall) COINS"; case .coinsM: return "\(e.coinPackMedium) COINS"
        case .coinsL: return "\(e.coinPackLarge) COINS"; default: return "" }
    }
}
