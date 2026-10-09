import XCTest
import AppKit

final class RecognitionTests: XCTestCase {
    @MainActor
    func testStalePublicationAfterReplacementAndClear() {
        let identity = OperationIdentity()
        let first = identity.advance()
        XCTAssertTrue(identity.isCurrent(first))
        let second = identity.advance()
        XCTAssertFalse(identity.isCurrent(first))
        XCTAssertTrue(identity.isCurrent(second))
        identity.advance()
        XCTAssertFalse(identity.isCurrent(second))
    }

    @MainActor
    func testWorkerReceivesFrozenInputsOffMainThread() async throws {
        let options = RecognitionOptions(fast: false, languageCode: "en-US", keepLineBreaks: true, append: true, processing: true, commandTemplate: "say [ocr]")
        let worker = RecognitionWorker(operation: { data, snapshot in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(data, Data([1, 2, 3]))
            XCTAssertEqual(snapshot.languageCode, "en-US")
            XCTAssertTrue(snapshot.append)
            XCTAssertEqual(snapshot.commandTemplate, "say [ocr]")
            return "recognized"
        })
        let output = try await worker.recognize(imageData: Data([1, 2, 3]), options: options)
        XCTAssertEqual(output, "recognized")
    }
}
