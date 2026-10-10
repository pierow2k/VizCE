import Foundation

class TextItem: Identifiable, Codable {
    let id: String
    var text: String

    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}
