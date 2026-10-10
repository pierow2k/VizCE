import SwiftUI

struct PreviewCloseHeader: View {
    let close: @MainActor () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: close) {
                Label("Close preview", systemImage: "x.circle.fill")
            }
            .buttonStyle(SimpleButtonStyle(help: "Close", color: .primary, size: 14))
        }
        .padding(2)
    }
}
