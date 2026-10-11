import AlinFoundation
import SwiftUI

/// A floating preview of the most recently published color and its clipboard representations.
struct ColorPreviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewCloseHeader(close: PreviewWindowController.shared.close)

            VStack(alignment: .leading) {
                Text("Hex: \(AppState.shared.colorSample.hex)")
                Text("RGB: \(AppState.shared.colorSample.rgb)")
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppState.shared.colorSample.color)
            }
            .padding([.horizontal, .bottom])
        }
        .foregroundStyle(.primary)
        .material(.sidebar)
    }
}
