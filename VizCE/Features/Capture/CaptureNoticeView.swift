import SwiftUI

/// A capture notice with selectable details and a keyboard-accessible dismissal action.
struct CaptureNoticeView: View {
    let title: LocalizedStringResource
    let message: String
    let close: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ScrollView {
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack {
                Spacer()
                Button("OK", action: close).keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}
