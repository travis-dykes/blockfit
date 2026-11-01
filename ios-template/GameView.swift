import SwiftUI
import SpriteKit

/// Classic mode, straight in: no menus (BF-009).
struct GameView: View {
    @StateObject private var debug = DebugSettings()
    @State private var scene = BoardScene(seed: 1)
    @State private var showDebug = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
            #if DEBUG
            Button { showDebug = true } label: {
                Image(systemName: "ladybug").padding(12).background(.black.opacity(0.4), in: Circle())
            }
            .padding(.leading, 28).padding(.top, 4)
            .accessibilityLabel("Debug menu")
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $showDebug) { DebugMenu(settings: debug) }
        .onChange(of: debug.restartToken) { _, _ in
            scene.restart(seed: debug.seed ?? 1, cometEnabled: debug.cometEnabled, comboSetup: debug.comboSetup)
        }
        .onChange(of: debug.cometEnabled) { _, on in
            scene.restart(seed: debug.seed ?? 1, cometEnabled: on, comboSetup: debug.comboSetup)
        }
        #endif
    }
}

#Preview { GameView() }
