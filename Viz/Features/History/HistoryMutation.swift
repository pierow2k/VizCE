import Foundation

/// An ordered edit that can be replayed on history loaded from disk.
enum HistoryMutation {
    /// An insertion replayed after any earlier buffered edits.
    case append(StoredHistoryEntry)
    /// Deletion of every entry matching the supplied identifier.
    case delete(String)
    case clear

    /// Mutates a snapshot by appending, deleting matching identities, or clearing all entries.
    func apply(to entries: inout [StoredHistoryEntry]) {
        switch self {
        case .append(let entry): entries.append(entry)
        case .delete(let id): entries.removeAll { $0.id == id }
        case .clear: entries.removeAll()
        }
    }
}
