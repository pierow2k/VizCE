import SwiftUI

struct SpacedToggleSeconds: ToggleStyle {
    @AppStorage("previewSeconds") var seconds: Double = 5.0

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

            Spacer() // Adds space between the label and the switch

            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .labelsHidden() // Hide default labels of the switch to use the custom label
        }
    }
}