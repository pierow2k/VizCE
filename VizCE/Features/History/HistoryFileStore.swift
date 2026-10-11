import Foundation

/// An actor that reads and atomically replaces a local JSON history file.
actor HistoryFileStore: HistoryStoring {
    private let url: URL

    /// Creates a file store targeting the supplied local history JSON URL.
    init(url: URL) { self.url = url }

    /// Decodes the history file, returning an empty snapshot when the file does not exist.
    ///
    /// - Throws: File read or JSON decoding errors; invalid history is not treated as empty.
    func load() throws -> [StoredHistoryEntry] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([StoredHistoryEntry].self, from: Data(contentsOf: url))
    }

    /// Encodes and atomically replaces the history file, creating parent directories if needed.
    ///
    /// - Throws: JSON encoding, directory creation, or file write errors.
    func save(_ entries: [StoredHistoryEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
