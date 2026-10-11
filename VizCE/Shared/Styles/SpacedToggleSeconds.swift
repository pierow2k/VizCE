import SwiftUI

/// A preview switch with a picker for its automatic dismissal delay.
struct SpacedToggleSeconds: ToggleStyle {
    /// The preview dismissal delay in seconds.
    @Binding var seconds: Double

    /// Builds the preview switch with dismissal choices of 3, 5, 10, 20, 30, and 60 seconds.
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {

            configuration.label

            Picker("Preview duration", selection: $seconds) {
                Text("3s").tag(3.0)
                Text("5s").tag(5.0)
                Text("10s").tag(10.0)
                Text("20s").tag(20.0)
                Text("30s").tag(30.0)
                Text("60s").tag(60.0)
            }
            .buttonStyle(.borderless)
            .labelsHidden()

            Spacer()

            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}