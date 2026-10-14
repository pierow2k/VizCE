import SwiftUI

/// An icon-only button with hover feedback that respects Reduce Motion.
struct SimpleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var hovered = false
    let help: String
    /// The full hover color, displayed at half opacity when the pointer is outside the button.
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
            .scaleEffect(hoverScale)
            .rotationEffect(hoverRotation)
            .animation(hoverAnimation, value: hovered)
            .foregroundStyle(hoverColor)
            .padding(padding)
            .onHover { hovering in
                hovered = hovering
            }
            .scaleEffect(pressedScale(isPressed: configuration.isPressed))
            .opacity(pressedOpacity(isPressed: configuration.isPressed))
            .help(help)
    }

    /// The 10% hover enlargement, disabled when Reduce Motion is enabled.
    private var hoverScale: CGFloat { !reduceMotion && hovered ? 1.1 : 1 }

    /// The optional quarter-turn on hover, disabled when Reduce Motion is enabled.
    private var hoverRotation: Angle { .degrees(!reduceMotion && rotate && hovered ? 90 : 0) }

    /// The 0.2-second hover transition, omitted when Reduce Motion is enabled.
    private var hoverAnimation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.2) }

    /// The hover color feedback, which remains active regardless of Reduce Motion.
    private var hoverColor: Color { hovered ? color : color.opacity(0.5) }

    /// Applies a 5% press contraction only when motion feedback is allowed.
    private func pressedScale(isPressed: Bool) -> CGFloat {
        !reduceMotion && isPressed ? 0.95 : 1
    }

    /// Dims pressed icons to 70% opacity instead of contracting them when Reduce Motion is enabled.
    private func pressedOpacity(isPressed: Bool) -> Double {
        reduceMotion && isPressed ? 0.7 : 1
    }
}
