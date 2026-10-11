import SwiftUI

/// An icon-only button with hover feedback that respects Reduce Motion.
struct SimpleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false
    let help: String
    var color: Color = .primary
    /// The icon font size and square content dimension in points.
    var size: CGFloat = 20
    /// The inset around the icon content in points.
    var padding: CGFloat = 5
    /// Whether hovering rotates the icon by 90 degrees when Reduce Motion is disabled.
    var rotate: Bool = false

    /// Builds icon feedback with optional hover rotation and an opacity-based press effect for Reduce Motion.
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