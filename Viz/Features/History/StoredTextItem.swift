import Foundation

struct StoredTextItem: Codable, Sendable, Equatable {
    let id: String
    let text: String
}
