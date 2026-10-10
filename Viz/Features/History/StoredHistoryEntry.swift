import Foundation

/// Associated-value encoding intentionally matches the existing HistoryEntry JSON.
enum StoredHistoryEntry: Codable, Sendable, Equatable, Identifiable {
    case text(StoredTextItem)
    case color(StoredColorItem)

    var id: String {
        switch self {
        case .text(let item): item.id
        case .color(let item): item.id
        }
    }
}
