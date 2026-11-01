import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Sound", isOn: $app.save.settings.sound)
                Toggle("Music", isOn: $app.save.settings.music)
                Toggle("Haptics", isOn: $app.save.settings.haptics)
                Toggle("Colorblind glyphs", isOn: $app.save.settings.colorblind)
                Button("Restore purchases") { app.restorePurchases() }
                Section("About") { Text("Block Fit — One Bit Holding. Spread joy.") }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back") { app.route = .home } } }
        }
    }
}
