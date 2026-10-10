import SwiftUI
import KeyboardShortcuts

struct RoundedRectangleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    let image: String
    let size: CGFloat
    let color: Color?
    let shortcut: KeyboardShortcuts.Shortcut?

    init(image: String, size: CGFloat, color: Color? = .primary, shortcut: KeyboardShortcuts.Shortcut? = nil) {
        self.image = image
        self.size = size
        self.color = color
        self.shortcut = shortcut
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: image)
                    .font(.system(size: size))
                    .foregroundStyle(color ?? .primary)
                configuration.label
                    .font(.footnote)

                if let shortcut = shortcut {
                    Text(shortcut.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(isHovered ? Color.primary.opacity(0.3) : Color.primary.opacity(0.1))
        .foregroundStyle(.primary)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isHovered)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scaleEffect(!reduceMotion && configuration.isPressed ? 0.95 : 1.0)
        .opacity(reduceMotion && configuration.isPressed ? 0.7 : 1)
        .onHover { inside in
            isHovered = inside
        }
    }
}