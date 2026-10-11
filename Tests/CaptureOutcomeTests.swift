import AppKit
import XCTest

final class CaptureOutcomeTests: XCTestCase {
    private let options = RecognitionOptions(fast: false, languageCode: nil, keepLineBreaks: true, append: false, processing: false, commandTemplate: "")

    func testEmptyRecognitionAndErrorsAreTyped() async {
        let empty = await RecognitionWorker { _, _ in "" }.outcome(imageData: Data(), options: options)
        XCTAssertEqual(empty, .noContent)
        let failed = await RecognitionWorker { _, _ in throw CocoaError(.fileReadCorruptFile) }
            .outcome(imageData: Data(), options: options)
        guard case .failure(.recognition) = failed else { XCTFail("Expected typed error")
return }
    }

    @MainActor
    func testOnlyContentPublishesAndEveryOutcomeCompletesOnce() {
        let outcomes: [RecognitionOutcome] = [.content("Unable to extract is legitimate text"), .noContent,
                                              .failure(.imageConversion), .cancelled]
        var published: [String] = []
        var notices: [RecognitionOutcome] = []
        var completions: [RecognitionOutcome] = []
        for outcome in outcomes {
            RecognitionDelivery.finish(outcome, valid: true, current: true, publish: { published.append($0) },
                                       notice: { notices.append($0) }, completion: { completions.append($0) })
        }
        XCTAssertEqual(published, ["Unable to extract is legitimate text"])
        XCTAssertEqual(notices, [.noContent, .failure(.imageConversion)])
        XCTAssertEqual(completions, outcomes)
    }

    @MainActor
    func testClearCompletesAsCancellationAndOlderErrorsProduceNoNotice() {
        var published = false
        var noticed = false
        var completions: [RecognitionOutcome] = []
        RecognitionDelivery.finish(.content("stale"), valid: false, current: false,
                                   publish: { _ in published = true }, notice: { _ in noticed = true },
                                   completion: { completions.append($0) })
        RecognitionDelivery.finish(.failure(.imageConversion), valid: true, current: false,
                                   publish: { _ in published = true }, notice: { _ in noticed = true },
                                   completion: { completions.append($0) })
        XCTAssertFalse(published)
        XCTAssertFalse(noticed)
        XCTAssertEqual(completions, [.cancelled, .failure(.imageConversion)])
    }

    @MainActor
    func testCancelledSelectionNeverReadsOldClipboardImage() async throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let image = NSImage(size: NSSize(width: 10, height: 10))
        pasteboard.writeObjects([image])
        let before = pasteboard.changeCount
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let worker = ScreenCaptureWorker(executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root) { _ in ["-c", "exit 1"] }
        let outcome = await worker.capture()
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(pasteboard.changeCount, before)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    @MainActor
    func testOwnedOutputIgnoresConcurrentClipboardChangeAndCleansUp() async throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.setString("old", forType: .string)
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let worker = ScreenCaptureWorker(executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root) { output in
            ["-c", "printf owned > \"$1\"", "vizce-test", output.path]
        }
        let task = Task { await worker.capture() }
        pasteboard.setString("new clipboard", forType: .string)
        let outcome = await task.value
        XCTAssertEqual(outcome, .image(Data("owned".utf8)))
        XCTAssertEqual(pasteboard.string(forType: .string), "new clipboard")
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    func testLaunchAndExecutionFailuresCleanTemporaryFiles() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let missing = await ScreenCaptureWorker(executable: URL(fileURLWithPath: "/missing-vizce-process"), temporaryDirectory: root).capture()
        guard case .failure(.screenCapture) = missing else { XCTFail("Expected launch failure")
return }
        let failed = await ScreenCaptureWorker(executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root) { _ in
            ["-c", "print -u2 permission-failure; exit 2"]
        }.capture()
        guard case .failure(.screenCapture(let message)) = failed else { XCTFail("Expected execution failure")
return }
        XCTAssertTrue(message.contains("permission-failure"))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    func testCancellationStopsProcessAndCleansUp() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let worker = ScreenCaptureWorker(executable: URL(fileURLWithPath: "/bin/sleep"), temporaryDirectory: root) { _ in ["10"] }
        let task = Task { await worker.capture() }
        while !FileManager.default.fileExists(atPath: root.path) { await Task.yield() }
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, .cancelled)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    func testFilelessSuccessIsCancellationAndEmptyOutputIsFailure() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let cancelled = await ScreenCaptureWorker(
            executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root
        ) { _ in ["-c", "exit 0"] }.capture()
        XCTAssertEqual(cancelled, .cancelled)
        let empty = await ScreenCaptureWorker(
            executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root
        ) { output in ["-c", "printf '' > \"$1\"", "vizce-test", output.path] }.capture()
        guard case .failure(.screenCapture) = empty else { XCTFail("Empty owned output must fail")
return }
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    func testDiagnosticExitOneIsFailureRatherThanCancellation() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let failed = await ScreenCaptureWorker(
            executable: URL(fileURLWithPath: "/bin/zsh"), temporaryDirectory: root
        ) { _ in ["-c", "print -u2 capture-failed; exit 1"] }.capture()
        guard case .failure(.screenCapture(let message)) = failed else { XCTFail("Expected diagnostic failure")
return }
        XCTAssertEqual(message, "capture-failed")
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
}
