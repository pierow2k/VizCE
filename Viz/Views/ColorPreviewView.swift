import SwiftUI
import AlinFoundation

struct ColorPreviewView: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()

                Button {
                    PreviewWindowController.shared.close()
                } label: {
                    Label("Close preview", systemImage: "x.circle.fill")
                }
                .buttonStyle(SimpleButtonStyle(help: "Close", color: .primary, size: 14))
            }
            .padding(2)

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
