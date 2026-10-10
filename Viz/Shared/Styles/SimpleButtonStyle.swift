import SwiftUI

struct SimpleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let help: String
    var color: Color = .primary
    var size: CGFloat = 20
    var padding: CGFloat = 5
    var rotate: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: size))
            .frame(width: size, height: size)
            .scaleEffect(!reduceMotion && hovered ? 1.1 : 1)
            .rotationEffect(.degrees(!reduceMotion && rotate && hovered ? 90 : 0))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: hovered)
            .foregroundStyle(hovered ? color : color.opacity(0.5))
            .padding(padding)
            .onHover { hovering in
                hovered = hovering
            }
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.95 : 1)
            .opacity(reduceMotion && configuration.isPressed ? 0.7 : 1)
            .help(help)
    }
}