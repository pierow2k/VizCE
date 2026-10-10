import SwiftUI

@available(macOS 15, *)
struct ModernSettingsTabs: View {
    @Binding var selection: SettingsTab

    var body: some View {
        TabView(selection: $selection) {
            Tab("General", systemImage: "gear", value: .general) { GeneralSettingsTab() }
            Tab("Shortcuts", systemImage: "keyboard", value: .shortcuts) { ShortcutsSettingsView() }
            Tab("Updates", systemImage: "arrow.down.circle", value: .updates) { UpdaterSettingsView() }
            Tab("About", systemImage: "info.circle", value: .about) { ScrollView { AboutView() } }
        }
    }
}
