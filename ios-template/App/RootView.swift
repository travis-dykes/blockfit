import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        switch app.route {
        case .home: HomeView()
        case .map: MapView()
        case .shop: ShopView()
        case .settings: SettingsView()
        case .play: GameScreen()
        }
    }
}
