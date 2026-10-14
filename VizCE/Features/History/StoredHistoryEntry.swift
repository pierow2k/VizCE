import Foundation

/// An immutable history record whose synthesized encoding preserves the existing history JSON
/// format.
enum StoredHistoryEntry: Codable, Sendable, Equatable, Identifiable {
    /// An immutable color record using the existing associated-value JSON shape.
    case color(StoredColorItem)
    /// An immutable text record using the existing associated-value JSON shape.
    case text(StoredTextItem)

    var id: String {
        switch self {
        case .text(let item):
            item.id

        case .color(let item):
            item.id
        }
    }
}
