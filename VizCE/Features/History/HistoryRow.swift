import SwiftUI
import AlinFoundation

/// A capture row with copy confirmation, optional link navigation, and a delete action.
struct HistoryRow: View {
    let entry: HistoryEntry
    @ObservedObject var feedback: CopyFeedbackController
    let delete: @MainActor () -> Void

    var body: some View {
        HStack {
            switch entry {
            case .color(let item):
                HStack {
                    VStack(alignment: .leading) {
                        Button { copy(item.hex) } label: { Text("HEX: \(item.hex)") }
                            .accessibilityLabel("Copy hexadecimal color")
                            .accessibilityValue(Text(item.hex))
                        Button { copy(item.rgb) } label: {
                            Text("RGB: \(item.rgb)").font(.footnote).foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Copy RGB color")
                        .accessibilityValue(Text(item.rgb))
                    }
                    .padding()
                    TrailingRoundedRectangle(cornerRadius: 8).fill(item.color)
                        .frame(maxWidth: .infinity).accessibilityHidden(true)
                }
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            case .text(let item):
                if let url = recognizedURL(item.text) {
                    Button { NSWorkspace.shared.open(url) } label: {
                        Label("Open captured link", systemImage: "safari").labelStyle(.iconOnly)
                    }
                    .help("Open captured link")
                }
                Button { copy(item.text) } label: {
                    Text(item.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("Copy captured text")
                .accessibilityValue(Text(item.text))
            }
            if feedback.copiedID == entry.id {
                Label("Copied", systemImage: "checkmark").font(.caption).foregroundStyle(.green)
            }
            Button(action: delete) {
                Label("Delete history item", systemImage: "xmark.circle.fill").labelStyle(.iconOnly)
            }
            .help("Delete history item")
        }
        .buttonStyle(.plain)
    }

    /// Copies a row value to the clipboard and replaces the visible copy confirmation.
    private func copy(_ value: String) {
        copyToClipboard(value)
        feedback.show(id: entry.id)
    }

    /// Trims captured text and adds HTTPS to recognized host-like values that lack an HTTP prefix.
    ///
    /// - Returns: A URL only when the trimmed text matches the history link pattern and can be parsed.
    private func recognizedURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isRecognizedURLFormat(trimmed) else { return nil }
        return URL(string: trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)")
    }
}
