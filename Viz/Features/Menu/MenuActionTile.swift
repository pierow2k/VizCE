import KeyboardShortcuts
import SwiftUI

struct MenuActionTile: View {
    let title: LocalizedStringResource
    let icon: String
    let help: LocalizedStringResource
    let shortcut: KeyboardShortcuts.Name
    let shortcutLabel: LocalizedStringResource
    let action: @MainActor () -> Void

    var body: some View {
        VStack {
            Button(action: action) { Text(title) }
                .help(Text(help))
                .buttonStyle(RoundedRectangleButtonStyle(image: icon, size: 15))
            ShortcutEditorView(name: shortcut, actionLabel: shortcutLabel)
        }
    }
}
