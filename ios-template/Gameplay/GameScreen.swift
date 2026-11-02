import SwiftUI
import SpriteKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

struct GameScreen: View {
    @EnvironmentObject var app: AppState
    #if DEBUG
    @StateObject private var debug = DebugSettings()
    @State private var showDebug = false
    #endif

    var body: some View {
        ZStack {
            if let scene = app.scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder]).ignoresSafeArea()
            }
            VStack {
                HStack {
                    Button { app.goHome() } label: {
                        Image(systemName: "pause.fill").padding(12).background(Color.bf.purple, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                    }.accessibilityLabel("Pause").padding(.leading, 24)
                    #if DEBUG
                    Button { showDebug = true } label: { Image(systemName: "ladybug").padding(12).foregroundStyle(.white) }
                    #endif
                    Spacer()
                }
                Spacer()
                if app.mode != .classic { boosterRow }
            }.padding(.bottom, 4)
            overlayView
        }
        #if DEBUG
        .sheet(isPresented: $showDebug) { DebugMenu(settings: debug) }
        .onChange(of: debug.restartToken) { _, _ in
            app.scene?.restart(seed: debug.seed ?? 1, cometEnabled: debug.cometEnabled, comboSetup: debug.comboSetup)
        }
        .onChange(of: debug.cometEnabled) { _, on in
            app.scene?.restart(seed: debug.seed ?? 1, cometEnabled: on, comboSetup: debug.comboSetup)
        }
        #endif
    }

    /// Booster row sits under the tray (design.md §1); counts shown as badges.
    private var boosterRow: some View {
        HStack(spacing: 8) {
            ForEach(Booster.allCases, id: \.self) { b in
                let n = app.save.wallet.boosters[b] ?? 0
                Button { app.useBooster(b) } label: {
                    BFText("\(b.rawValue.uppercased()) x\(n)")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.bf.purple, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bf.ink, lineWidth: 3))
                        .opacity(n > 0 ? 1 : 0.45)
                }.disabled(n == 0).accessibilityLabel("\(b.rawValue), \(n) left")
            }
        }.padding(.horizontal, 20).id(app.boostersTick)
    }

    @ViewBuilder private var overlayView: some View {
        switch app.overlay {
        case .none: EmptyView()
        case .win(let info): dim { WinCard(info: info) }
        case .lose: dim { LoseCard() }
        case .classicOver(let s, let b): dim { ClassicOverCard(score: s, best: b) }
        case .starterPack: dim { StarterPackCard() }
        }
    }
    private func dim<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        ZStack { Color.black.opacity(0.55).ignoresSafeArea(); c() }
    }
}
