import XCTest

final class HistoryActionTests: XCTestCase {
    func testStableFiltersSelectExpectedKinds() {
        XCTAssertTrue(HistoryFilter.all.includes(isText: true))
        XCTAssertTrue(HistoryFilter.all.includes(isText: false))
        XCTAssertTrue(HistoryFilter.text.includes(isText: true))
        XCTAssertFalse(HistoryFilter.text.includes(isText: false))
        XCTAssertFalse(HistoryFilter.colors.includes(isText: true))
        XCTAssertTrue(HistoryFilter.colors.includes(isText: false))
        XCTAssertEqual(HistoryFilter.all.rawValue, "all")
        XCTAssertEqual(HistoryFilter.allCases, [.all, .text, .colors])
        XCTAssertEqual(HistoryFilter.allCases.map(\.rawValue), ["all", "text", "colors"])
    }

    @MainActor
    func testOlderCopyExpiryCannotClearNewFeedback() async {
        let clock = CopyFeedbackClock()
        let feedback = CopyFeedbackController { await clock.sleep() }
        feedback.show(id: "one")
        await clock.waitFor(1)
        feedback.show(id: "two")
        await clock.waitFor(2)
        await clock.finish(0)
        for _ in 0..<20 { await Task.yield() }
        XCTAssertEqual(feedback.copiedID, "two")
        await clock.finish(1)
        for _ in 0..<20 { await Task.yield() }
        XCTAssertNil(feedback.copiedID)
    }

    @MainActor
    func testDeletionIsIndependentOfCopyFeedbackAndClearCancelsExpiry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = HistoryFileStore(url: directory.appendingPathComponent("history.json"))
        let repository = HistoryRepository(store: store)
        try await repository.flush()
        let clock = CopyFeedbackClock()
        let feedback = CopyFeedbackController { await clock.sleep() }
        repository.append(.text(StoredTextItem(id: "copied", text: "content")))
        feedback.show(id: "copied")
        await clock.waitFor(1)
        repository.delete(id: "copied")
        XCTAssertTrue(repository.items.isEmpty)
        feedback.clear()
        await clock.finish(0)
        for _ in 0..<20 { await Task.yield() }
        XCTAssertNil(feedback.copiedID)
        try await repository.flush()
    }
}

/// A manual feedback clock that retains canceled sleepers to exercise generation checks.
private actor CopyFeedbackClock {
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func sleep() async { await withCheckedContinuation { continuations.append($0) } }
    func waitFor(_ count: Int) async { while continuations.count < count { await Task.yield() } }
    func finish(_ index: Int) { continuations[index].resume() }
}
