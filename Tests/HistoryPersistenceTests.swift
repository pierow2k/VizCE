import XCTest
import Foundation

final class HistoryPersistenceTests: XCTestCase {
    private func entry(_ id: String) -> StoredHistoryEntry {
        .text(StoredTextItem(id: id, text: "text \(id)"))
    }

    func testLegacyEncodingAndAtomicRoundTrip() async throws {
        let json = ##"[{"text":{"_0":{"id":"old-text","text":"hello"}}},{"color":{"_0":{"id":"old-color","hex":"#123456","rgb":"(18,52,86)"}}}]"##.data(using: .utf8)!
        let records = try JSONDecoder().decode([StoredHistoryEntry].self, from: json)
        let encoded = try JSONEncoder().encode(records)
        XCTAssertEqual(try JSONSerialization.jsonObject(with: encoded) as? NSArray,
                       try JSONSerialization.jsonObject(with: json) as? NSArray)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = HistoryFileStore(url: dir.appendingPathComponent("historyItems.json"))
        try await store.save(records)
        let loaded = try await store.load()
        XCTAssertEqual(loaded, records)
        XCTAssertEqual(loaded.map(\.id), ["old-text", "old-color"])
    }

    @MainActor
    func testEditsDuringLoadAndClearDoNotResurrectOldEntries() async throws {
        let store = ControlledHistoryStore(holdLoad: true)
        let repository = HistoryRepository(store: store)
        repository.append(entry("new"))
        repository.delete(id: "old")
        repository.clear()
        repository.append(entry("final"))
        await store.waitForLoad()
        await store.finishLoad([entry("old")])
        try await repository.flush()
        XCTAssertEqual(repository.items.map(\.id), ["final"])
        let saves = await store.saves
        XCTAssertEqual(saves.last?.map(\.id), ["final"])
    }

    @MainActor
    func testOnlyPendingSnapshotsCoalesceAndFlushWaits() async throws {
        let store = ControlledHistoryStore(holdSave: true)
        let repository = HistoryRepository(store: store)
        try await repository.flush()
        repository.append(entry("one"))
        await store.waitForSave()
        repository.append(entry("two"))
        repository.append(entry("three"))
        var finished = false
        let flush = Task { try await repository.flush(); finished = true }
        await Task.yield()
        XCTAssertFalse(finished)
        await store.finishSave()
        try await flush.value
        let saves = await store.saves
        XCTAssertEqual(saves.map { $0.map(\.id) }, [["one"], ["one", "two", "three"]])
    }

    @MainActor
    func testSaveFailureRetainsNewestSnapshotForRetry() async throws {
        let store = ControlledHistoryStore(failSave: true)
        let repository = HistoryRepository(store: store)
        try await repository.flush()
        repository.append(entry("one"))
        do { try await repository.flush(); XCTFail("Expected write failure") } catch {}
        XCTAssertNotNil(repository.failure)
        repository.append(entry("two"))
        await store.allowSave()
        repository.retry()
        try await repository.flush()
        XCTAssertNil(repository.failure)
        let saves = await store.saves
        XCTAssertEqual(saves.last?.map(\.id), ["one", "two"])
    }

    @MainActor
    func testReadFailureNeverOverwritesOriginalFile() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("historyItems.json")
        let original = Data("invalid json".utf8)
        try original.write(to: url)
        let repository = HistoryRepository(store: HistoryFileStore(url: url))
        repository.clear()
        repository.append(entry("new"))
        do { try await repository.flush(); XCTFail("Expected read failure") } catch {}
        XCTAssertEqual(try Data(contentsOf: url), original)
        try JSONEncoder().encode([entry("old")]).write(to: url)
        repository.retry()
        try await repository.flush()
        XCTAssertEqual(repository.items.map(\.id), ["new"])
    }

    func testAtomicWriteFailurePreservesExistingDestination() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let blocked = dir.appendingPathComponent("blocked")
        try Data("unchanged".utf8).write(to: blocked)
        let store = HistoryFileStore(url: blocked.appendingPathComponent("historyItems.json"))
        do { try await store.save([entry("new")]); XCTFail("Expected write failure") } catch {}
        XCTAssertEqual(try String(contentsOf: blocked, encoding: .utf8), "unchanged")
    }
}

/// A history fixture with held loads, a held first save, and switchable write failures.
private actor ControlledHistoryStore: HistoryStoring {
    var saves: [[StoredHistoryEntry]] = []
    private var loadContinuation: CheckedContinuation<[StoredHistoryEntry], Never>?
    private var saveContinuation: CheckedContinuation<Void, Never>?
    private let holdLoad: Bool
    /// Whether the first successful save waits for explicit release; later saves complete immediately.
    private var holdSave: Bool
    private var failSave: Bool

    /// Configures whether loading, the first save, or all saves are blocked for persistence tests.
    ///
    /// - Parameters:
    ///   - holdLoad: Whether loading waits for `finishLoad(_:)`.
    ///   - holdSave: Whether the first successful save waits for `finishSave()`.
    ///   - failSave: Whether saves throw until `allowSave()` is called.
    init(holdLoad: Bool = false, holdSave: Bool = false, failSave: Bool = false) {
        self.holdLoad = holdLoad
        self.holdSave = holdSave
        self.failSave = failSave
    }
    func load() async -> [StoredHistoryEntry] {
        if holdLoad { return await withCheckedContinuation { loadContinuation = $0 } }
        return []
    }
    func save(_ entries: [StoredHistoryEntry]) async throws {
        if failSave { throw CocoaError(.fileWriteNoPermission) }
        saves.append(entries)
        if holdSave {
            holdSave = false
            await withCheckedContinuation { saveContinuation = $0 }
        }
    }
    func waitForLoad() async { while loadContinuation == nil { await Task.yield() } }
    func finishLoad(_ entries: [StoredHistoryEntry]) { loadContinuation?.resume(returning: entries); loadContinuation = nil }
    func waitForSave() async { while saveContinuation == nil { await Task.yield() } }
    func finishSave() { saveContinuation?.resume(); saveContinuation = nil }
    func allowSave() { failSave = false }
}
