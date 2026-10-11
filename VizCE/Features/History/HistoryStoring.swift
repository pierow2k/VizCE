import Foundation

/// An asynchronous persistence boundary for immutable history snapshots.
protocol HistoryStoring: Sendable {
    /// Loads an immutable history snapshot or throws a persistence error.
    func load() async throws -> [StoredHistoryEntry]
    /// Persists the supplied snapshot or throws a persistence error.
    func save(_ entries: [StoredHistoryEntry]) async throws
}
