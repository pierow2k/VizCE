import Foundation

/// Blocking file access and JSON coding run exclusively on this actor's executor.
actor HistoryFileStore: HistoryStoring {
    private let url: URL

    init(url: URL) { self.url = url }

    func load() throws -> [StoredHistoryEntry] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([StoredHistoryEntry].self, from: Data(contentsOf: url))
    }

    func save(_ entries: [StoredHistoryEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
