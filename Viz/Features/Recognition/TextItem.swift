import Foundation

/// A mutable text capture with a stable identifier for preview and history.
class TextItem: Identifiable, Codable {
    let id: String
    var text: String

    /// Creates a text capture, preserving a supplied history identifier or generating a new one.
    ///
    /// - Parameters:
    ///   - id: The stable identity shared by preview and history.
    ///   - text: The recognized content to display and copy.
    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}
