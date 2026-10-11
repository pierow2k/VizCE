import AppKit

/// Replaces the general clipboard with capture text joined by newline separators.
///
/// An empty array writes an empty string.
@MainActor
func copyTextItemsToClipboard(textItems: [TextItem]) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    let combinedText = textItems.map(\.text).joined(separator: "\n")
    pasteboard.setString(combinedText, forType: .string)
}

/// Replaces the general clipboard with the captured color’s hexadecimal representation.
@MainActor
func copyColorsToClipboard(color: ColorItem) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(color.hex, forType: .string)
}
