import SwiftUI

struct LegacySettingsTabs: View {
    @Binding var selection: SettingsTab

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(SettingsTab.general)
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsTab.shortcuts)
            UpdaterSettingsView()
                .tabItem { Label("Updates", systemImage: "arrow.down.circle") }
                .tag(SettingsTab.updates)
            ScrollView { AboutView() }
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
    }
}
