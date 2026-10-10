import Foundation

/// An immutable text record for JSON persistence and transfer across concurrency boundaries.
struct StoredTextItem: Codable, Sendable, Equatable {
    let id: String
    let text: String
}
