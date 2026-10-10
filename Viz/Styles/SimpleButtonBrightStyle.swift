import SwiftUI

struct SimpleButtonBrightStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let help: String
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 20))
            .foregroundStyle(hovered ? color.opacity(0.5) : color)
            .padding(5)
            .onHover { hovering in
                hovered = hovering
            }
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.95 : 1)
            .opacity(reduceMotion && configuration.isPressed ? 0.7 : 1)
            .animation(reduceMotion ? nil : .default, value: hovered)
            .help(help)
    }
}