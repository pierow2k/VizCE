import XCTest

final class PreviewTests: XCTestCase {
    @MainActor
    func testCancellationWakesSleepingTask() async {
        var started = false
        var returned = false
        let expiry = PreviewExpiry(sleep: { duration in
            started = true
            defer { returned = true }
            try await Task.sleep(for: duration)
        })
        expiry.schedule(after: .seconds(3600)) { XCTFail("Canceled expiry fired") }
        while !started { await Task.yield() }
        expiry.cancel()
        for _ in 0..<100 where !returned { await Task.yield() }
        XCTAssertTrue(returned)
    }

    @MainActor
    func testReplacementCannotCloseNewPresentation() async {
        let clock = ManualPreviewClock()
        let expiry = PreviewExpiry(sleep: clock.sleep)
        var closed: [Int] = []
        expiry.schedule(after: .seconds(5)) { closed.append(1) }
        await clock.waitForSleepers(1)
        expiry.schedule(after: .seconds(5)) { closed.append(2) }
        await clock.waitForSleepers(2)
        clock.finish(0)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(closed, [])
        clock.finish(1)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(closed, [2])
    }

    @MainActor
    func testManualCloseAndClearCancelExpiry() async {
        for _ in 0..<2 {
            let clock = ManualPreviewClock()
            let expiry = PreviewExpiry(sleep: clock.sleep)
            var closed = false
            expiry.schedule(after: .seconds(5)) { closed = true }
            await clock.waitForSleepers(1)
            expiry.cancel()
            // Even a clock that ignores cancellation cannot expire a canceled presentation.
            clock.finish(0)
            for _ in 0..<10 { await Task.yield() }
            XCTAssertFalse(closed)
        }
    }
}

@MainActor
private final class ManualPreviewClock {
    private var continuations: [CheckedContinuation<Void, Error>] = []
    func sleep(_ duration: Duration) async throws {
        try await withCheckedThrowingContinuation { continuations.append($0) }
    }
    func waitForSleepers(_ count: Int) async {
        while continuations.count < count { await Task.yield() }
    }
    func finish(_ index: Int) { continuations[index].resume() }
}
