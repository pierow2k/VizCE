import AppKit
import XCTest

final class WebcamTests: XCTestCase {
    @MainActor
    func testAppearanceAndDefaultPickerChangeShareOneStart() async {
        let auth = ControlledAuthorization()
        let backend = FakeWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(authorization: auth, backend: backend)
        coordinator.start(deviceID: "default")
        await auth.waitForRequests(1)
        coordinator.start(deviceID: "default")
        await auth.finish(0, allowed: true)
        await coordinator.waitForPendingOperation()
        let starts = await backend.starts
        XCTAssertEqual(starts.count, 1)
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testAuthorizationCompletingAfterCloseCannotStartCamera() async {
        let auth = ControlledAuthorization()
        let backend = FakeWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(authorization: auth, backend: backend)
        coordinator.start(deviceID: "A")
        await auth.waitForRequests(1)
        coordinator.stop()
        await auth.finish(0, allowed: true)
        await coordinator.waitForPendingOperation()
        for _ in 0..<20 { await Task.yield() }
        let starts = await backend.starts
        XCTAssertTrue(starts.isEmpty)
        XCTAssertFalse(coordinator.isPreviewActive)
    }

    @MainActor
    func testRapidCameraChangesUseOnlyLatestAuthorizedRequest() async {
        let auth = ControlledAuthorization()
        let backend = FakeWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(authorization: auth, backend: backend)
        for (index, device) in ["A", "B", "C"].enumerated() {
            coordinator.start(deviceID: device)
            await auth.waitForRequests(index + 1)
        }
        await auth.finish(2, allowed: true)
        await coordinator.waitForPendingOperation()
        await auth.finish(1, allowed: true)
        await auth.finish(0, allowed: true)
        for _ in 0..<20 { await Task.yield() }
        let starts = await backend.starts
        XCTAssertEqual(starts.map(\.device), ["C"])
        XCTAssertTrue(coordinator.isPreviewActive)
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testOverlappingStartsDiscardAndStopOlderCompletion() async {
        let backend = FakeWebcamBackend(holdStarts: true)
        let coordinator = WebcamCaptureCoordinator(authorization: AllowedAuthorization(), backend: backend)
        coordinator.start(deviceID: "A")
        await backend.waitForStarts(1)
        coordinator.start(deviceID: "B")
        await backend.waitForStarts(2)
        await backend.finishStart(1)
        await coordinator.waitForPendingOperation()
        await backend.finishStart(0)
        await backend.waitForStop(of: 1, count: 2)
        for _ in 0..<20 { await Task.yield() }
        XCTAssertTrue(coordinator.isPreviewActive)
        let starts = await backend.starts
        XCTAssertEqual(starts.map(\.device), ["A", "B"])
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testBackClearsImageAndStartsExactlyOnce() async throws {
        let backend = FakeWebcamBackend(imageData: try fixtureImage())
        let coordinator = WebcamCaptureCoordinator(authorization: AllowedAuthorization(), backend: backend)
        coordinator.start(deviceID: "A")
        await coordinator.waitForPendingOperation()
        coordinator.capturePhoto()
        await coordinator.waitForPendingOperation()
        XCTAssertNotNil(coordinator.capturedImage)
        XCTAssertFalse(coordinator.isPreviewActive)
        coordinator.restart(deviceID: "A")
        XCTAssertNil(coordinator.capturedImage)
        await coordinator.waitForPendingOperation()
        let starts = await backend.starts
        XCTAssertEqual(starts.map(\.device), ["A", "A"])
        XCTAssertTrue(coordinator.isPreviewActive)
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testCaptureCompletingAfterCloseCannotPublishImage() async throws {
        let backend = FakeWebcamBackend(imageData: try fixtureImage(), holdCapture: true)
        let coordinator = WebcamCaptureCoordinator(authorization: AllowedAuthorization(), backend: backend)
        var publications = 0
        coordinator.onCapture = { _ in publications += 1 }
        coordinator.start(deviceID: "A")
        await coordinator.waitForPendingOperation()
        coordinator.capturePhoto()
        await backend.waitForCapture()
        coordinator.stop()
        await backend.finishCapture()
        await coordinator.waitForPendingOperation()
        for _ in 0..<20 { await Task.yield() }
        XCTAssertNil(coordinator.capturedImage)
        XCTAssertEqual(publications, 0)
        XCTAssertFalse(coordinator.isPreviewActive)
    }

    @MainActor
    func testDeniedPermissionAndSetupErrorFinishStartup() async {
        let auth = ControlledAuthorization()
        let coordinator = WebcamCaptureCoordinator(authorization: auth, backend: FakeWebcamBackend())
        coordinator.start(deviceID: "A")
        await auth.waitForRequests(1)
        await auth.finish(0, allowed: false)
        await coordinator.waitForPendingOperation()
        XCTAssertTrue(coordinator.permissionDenied)
        XCTAssertFalse(coordinator.isStarting)
        let failing = WebcamCaptureCoordinator(
            authorization: AllowedAuthorization(),
            backend: FakeWebcamBackend(failStart: true)
        )
        failing.start(deviceID: "missing")
        await failing.waitForPendingOperation()
        guard case .failed(let message) = failing.state else {
            XCTFail("Expected failure state")
            return
        }
        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(failing.isStarting)
        XCTAssertFalse(failing.isPreviewActive)
    }

    func testDelegateDoesNotRetainWorker() throws {
        var worker: WebcamCaptureWorker? = WebcamCaptureWorker()
        weak let weakWorker = worker
        let delegate = VideoSampleDelegate(worker: try XCTUnwrap(worker))
        worker = nil
        XCTAssertNil(weakWorker)
        withExtendedLifetime(delegate) {
            // Keep the callback alive through the weak-worker assertion above.
        }
    }

    func testStopInvalidatesStartBeforeItReachesWorkerQueue() async {
        let worker = WebcamCaptureWorker()
        await worker.stop(operationID: 4)
        do {
            _ = try await worker.start(deviceID: "unused", operationID: 4)
            XCTFail("Stopped generation must not start")
        } catch {
            XCTAssertEqual(error as? WebcamCaptureError, .staleOperation)
        }
    }

    @MainActor
    private func fixtureImage() throws -> Data {
        let bitmap = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: 2,
                pixelsHigh: 2,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 8,
                bitsPerPixel: 32
            )
        )
        return try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
    }
}

private struct AllowedAuthorization: WebcamAuthorizing {
    func isAuthorized() -> Bool { true }
}

/// A permission fixture whose requests remain pending until explicitly released by index.
private actor ControlledAuthorization: WebcamAuthorizing {
    private var requests: [CheckedContinuation<Bool, Never>] = []

    func isAuthorized() async -> Bool {
        await withCheckedContinuation { requests.append($0) }
    }
    func waitForRequests(_ count: Int) async {
        while requests.count < count { await Task.yield() }
    }
    func finish(_ index: Int, allowed: Bool) { requests[index].resume(returning: allowed) }
}

/// A recording backend with independently held starts and captures for stale-completion tests.
private actor FakeWebcamBackend: WebcamCaptureBackend {
    struct Start: Sendable {
        let device: String
        let id: UInt64
    }

    private(set) var starts: [Start] = []
    private var stops: [UInt64] = []
    private var pendingStarts: [UInt64: CheckedContinuation<Void, Never>] = [:]
    private var pendingCapture: CheckedContinuation<Void, Never>?
    private let holdStarts: Bool
    private let imageData: Data
    private let holdCapture: Bool
    private let failStart: Bool

    /// Configures held operations, captured bytes, and camera setup failure for lifecycle tests.
    ///
    /// - Parameters:
    ///   - holdStarts: Whether each start waits for `finishStart(_:)`.
    ///   - imageData: The encoded still image returned by capture.
    ///   - holdCapture: Whether capture waits for `finishCapture()`.
    ///   - failStart: Whether startup throws after any held wait is released.
    init(holdStarts: Bool = false, imageData: Data = Data(), holdCapture: Bool = false, failStart: Bool = false) {
        self.holdStarts = holdStarts
        self.imageData = imageData
        self.holdCapture = holdCapture
        self.failStart = failStart
    }
    func start(deviceID: String, operationID: UInt64) async throws -> WebcamPreviewSource {
        starts.append(Start(device: deviceID, id: operationID))
        if holdStarts { await withCheckedContinuation { pendingStarts[operationID] = $0 } }
        if failStart { throw WebcamCaptureError.noDevice }
        return WebcamPreviewSource()
    }
    func capture(operationID _: UInt64) async -> Data {
        if holdCapture { await withCheckedContinuation { pendingCapture = $0 } }
        return imageData
    }
    func stop(operationID: UInt64) { stops.append(operationID) }
    func waitForStarts(_ count: Int) async {
        while starts.count < count { await Task.yield() }
    }
    func finishStart(_ index: Int) { pendingStarts.removeValue(forKey: starts[index].id)?.resume() }
    func waitForStop(of id: UInt64, count: Int = 1) async {
        while stops.filter({ $0 == id }).count < count { await Task.yield() }
    }
    func waitForCapture() async {
        while pendingCapture == nil { await Task.yield() }
    }
    func finishCapture() {
        pendingCapture?.resume()
        pendingCapture = nil
    }
}
