import AppKit
import Foundation
import KeyboardShortcuts
import SwiftUI

/// A shortcut badge that opens settings when a shortcut is assigned.
struct ShortcutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings
    let name: KeyboardShortcuts.Name
    let actionLabel: LocalizedStringResource

    var body: some View {
        if let shortcut = KeyboardShortcuts.getShortcut(for: name) {
            Button {
                UserDefaults.standard.set(SettingsTab.general.rawValue, forKey: "settingsSelectedTab")
                NSApp.activate()
                openSettings()
                dismiss()
            } label: {
                Text(shortcut.description)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(4)
                    .padding(.horizontal, 2)
                    .background {
                        Capsule().fill(Color.secondary.opacity(0.2))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(actionLabel))
            .accessibilityValue(Text(shortcut.description))
        }
    }
}
