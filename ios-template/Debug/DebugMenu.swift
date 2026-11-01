#if DEBUG
import SwiftUI

/// DEBUG-only menu stub (BF-008). Full menu lands in M4 (BF-420).
struct DebugMenu: View {
    @ObservedObject var settings: DebugSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Comet Clear (BF-008)") {
                    Toggle("Comet Clear", isOn: $settings.cometEnabled)
                }
                Section("Seed") {
                    TextField("Seed (number)", text: $settings.seedText).keyboardType(.numberPad)
                    Button("Restart with seed") { settings.restart(); dismiss() }
                }
                Section("Gate 0 capture (BF-010)") {
                    Button("3-line combo setup") { settings.restart(comboSetup: true); dismiss() }
                }
            }
            .navigationTitle("Debug")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
#endif
