import SwiftUI

struct PaddedProminentButtonStyle: PrimitiveButtonStyle {
    var icon: String? = nil
    var tint: Color? = .blue
    @State private var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                }
                configuration.label
            }
            .padding(5)

        }
        .buttonStyle(.borderedProminent)
        .tint(tint ?? .blue)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}