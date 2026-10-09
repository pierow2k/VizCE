import Foundation

enum HistoryMutation {
    case append(StoredHistoryEntry)
    case delete(String)
    case clear

    func apply(to entries: inout [StoredHistoryEntry]) {
        switch self {
        case .append(let entry): entries.append(entry)
        case .delete(let id): entries.removeAll { $0.id == id }
        case .clear: entries.removeAll()
        }
    }
}
