import Foundation

/// A mutable text capture with a stable identifier for preview and history.
class TextItem: Identifiable, Codable {
    let id: String
    var text: String

    /// Creates a text capture, preserving a supplied history identifier or generating a new one.
    ///
    /// - Parameters:
    ///   - text: The recognized content to display and copy.
    ///   - id: The stable identity shared by preview and history.
    init(text: String, id: String = UUID().uuidString) {
        self.id = id
        self.text = text
    }
}
