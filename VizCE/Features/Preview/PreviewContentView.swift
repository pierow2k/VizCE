import SwiftUI
import AlinFoundation

/// A preview of current text captures and any post-processing output.
struct PreviewContentView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var content = RecognizedContent.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewCloseHeader(close: PreviewWindowController.shared.close)

            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(content.items, id: \.id) { item in
                        let text = item.text
                        let trimmedText = text.last == "\n" ? String(text.dropLast()) : text
                        Text(trimmedText)
                            .textSelection(.enabled)
                    }
                }
            }
            .scrollIndicators(.visible)
            .padding([.horizontal, .bottom])
            .frame(minWidth: 200)

            Spacer()


            if !appState.cmdOutput.isEmpty {
                HStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .opacity(0.2)

                    Text("Processing Output")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .opacity(0.6)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 150)

                    Rectangle()
                        .frame(height: 1)
                        .opacity(0.2)
                }
                .frame(minHeight: 35)

                ScrollView {
                    Text(appState.cmdOutput)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.visible)
                .padding([.horizontal, .bottom])


            }
        }
        .foregroundStyle(.primary)
        .material(.sidebar)
    }
}
