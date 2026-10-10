import SwiftUI

/// A camera menu that displays the selected device and reports choices by identifier.
struct WebcamCameraPicker: View {
    let devices: [WebcamDevice]
    let selection: WebcamDevice?
    let choose: @MainActor (String) -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Menu {
                ForEach(devices) { device in Button(device.name) { choose(device.id) } }
            } label: {
                if let selection {
                    Text(selection.name).lineLimit(1).truncationMode(.middle)
                } else {
                    Text("Select Camera")
                }
            }
            .accessibilityLabel("Camera")
            .accessibilityValue(Text(selection?.name ?? ""))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8)
        .background(.ultraThinMaterial)
    }
}
