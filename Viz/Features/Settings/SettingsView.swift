//
//  SettingsView.swift
//  Viz
//
//  Created by Alin Lupascu on 3/27/25.
//

import SwiftUI

/// Persisted settings navigation with the tab presentation supported by the running macOS version.
struct SettingsView: View {
    @AppStorage("settingsSelectedTab") private var selectedTab = SettingsTab.general

    var body: some View {
        Group {
            if #available(macOS 15, *) {
                ModernSettingsTabs(selection: $selectedTab)
            } else {
                LegacySettingsTabs(selection: $selectedTab)
            }
        }
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 500, minHeight: 300, idealHeight: 600, maxHeight: .infinity)
        .background(Color("bg"))
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }
}
