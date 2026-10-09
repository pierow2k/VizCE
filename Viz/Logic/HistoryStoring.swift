import Foundation

protocol HistoryStoring: Sendable {
    func load() async throws -> [StoredHistoryEntry]
    func save(_ entries: [StoredHistoryEntry]) async throws
}
