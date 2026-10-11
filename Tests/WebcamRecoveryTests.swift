import AVFoundation
import XCTest

final class WebcamRecoveryTests: XCTestCase {
    @MainActor
    func testMissingSavedCameraFailsWithoutFallingBackAndRetryCanRecover() async {
        let backend = RecoveryWebcamBackend(error: .noDevice)
        let devices = StaticWebcamDevices()
        let coordinator = WebcamCaptureCoordinator(
            authorization: RecoveryAuthorization(allowed: true),
            backend: backend,
            devices: devices
        )
        coordinator.start(deviceID: "saved-camera")
        await coordinator.waitForPendingOperation()
        guard case .failed = coordinator.state else {
            XCTFail("Expected failed state")
            return
        }
        XCTAssertFalse(coordinator.isStarting)
        var starts = await backend.started
        XCTAssertEqual(starts, ["saved-camera"])
        await backend.setError(nil)
        coordinator.restart(deviceID: "replacement")
        await coordinator.waitForPendingOperation()
        XCTAssertEqual(coordinator.state, .previewing)
        starts = await backend.started
        XCTAssertEqual(starts, ["saved-camera", "replacement"])
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testEverySetupFailureFinishesStartingState() async {
        for error in [WebcamCaptureError.unsupportedInput, .unsupportedOutput, .startFailed] {
            let coordinator = WebcamCaptureCoordinator(
                authorization: RecoveryAuthorization(allowed: true),
                backend: RecoveryWebcamBackend(error: error)
            )
            coordinator.start(deviceID: "camera")
            await coordinator.waitForPendingOperation()
            guard case .failed(let message) = coordinator.state else {
                XCTFail("Expected error")
                return
            }
            XCTAssertFalse(message.isEmpty)
            XCTAssertFalse(coordinator.isStarting)
            XCTAssertFalse(coordinator.isPreviewActive)
            coordinator.stop()
            await coordinator.waitForPendingOperation()
        }
    }

    @MainActor
    func testPermissionDenialIsDistinctAndCannotStartSession() async {
        let backend = RecoveryWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(
            authorization: RecoveryAuthorization(allowed: false),
            backend: backend
        )
        coordinator.start(deviceID: "camera")
        await coordinator.waitForPendingOperation()
        XCTAssertEqual(coordinator.state, .permissionDenied)
        let starts = await backend.started
        XCTAssertTrue(starts.isEmpty)
    }

    @MainActor
    func testEmptySelectionResolvesPreferredDefaultBeforeStarting() async {
        let backend = RecoveryWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(
            authorization: RecoveryAuthorization(allowed: true),
            backend: backend,
            devices: StaticWebcamDevices()
        )
        coordinator.start(deviceID: "")
        await coordinator.waitForPendingOperation()
        let starts = await backend.started
        XCTAssertEqual(starts, ["preferred"])
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testCaptureFailureStopsSessionAndOffersRetry() async {
        let backend = RecoveryWebcamBackend()
        let coordinator = WebcamCaptureCoordinator(
            authorization: RecoveryAuthorization(allowed: true),
            backend: backend
        )
        coordinator.start(deviceID: "camera")
        await coordinator.waitForPendingOperation()
        coordinator.capturePhoto()
        await coordinator.waitForPendingOperation()
        guard case .failed = coordinator.state else {
            XCTFail("Expected capture error")
            return
        }
        XCTAssertNil(coordinator.previewLayer)
        XCTAssertFalse(coordinator.isPreviewActive)
        coordinator.restart(deviceID: "camera")
        await coordinator.waitForPendingOperation()
        XCTAssertEqual(coordinator.state, .previewing)
        coordinator.stop()
        await coordinator.waitForPendingOperation()
    }

    @MainActor
    func testLateDeviceCatalogCompletionAfterCloseCannotStartSession() async {
        let backend = RecoveryWebcamBackend()
        let devices = DelayedWebcamDevices()
        let coordinator = WebcamCaptureCoordinator(
            authorization: RecoveryAuthorization(allowed: true),
            backend: backend,
            devices: devices
        )
        coordinator.start(deviceID: "")
        await devices.waitForRequests(1)
        coordinator.stop()
        await devices.finish(0, id: "late")
        await coordinator.waitForPendingOperation()
        for _ in 0..<20 { await Task.yield() }
        let starts = await backend.started
        XCTAssertTrue(starts.isEmpty)
        XCTAssertEqual(coordinator.state, .idle)
    }

    @MainActor
    func testDeviceChoicesRefreshAndRejectOlderCatalogResult() async {
        let provider = DelayedWebcamDevices()
        let manager = WebcamManager(provider: provider)
        await provider.waitForRequests(1)
        manager.refresh()
        await provider.waitForRequests(2)
        await provider.finish(1, id: "new")
        await manager.waitForRefresh()
        await provider.finish(0, id: "old")
        for _ in 0..<20 { await Task.yield() }
        XCTAssertEqual(manager.availableDevices.map(\.id), ["new"])
        XCTAssertEqual(manager.defaultDevice?.id, "new")
    }
}

private struct RecoveryAuthorization: WebcamAuthorizing {
    let allowed: Bool

    func isAuthorized() -> Bool { allowed }
}

/// A backend with switchable startup failure and a deliberately unavailable capture frame.
private actor RecoveryWebcamBackend: WebcamCaptureBackend {
    var started: [String] = []
    private var error: WebcamCaptureError?

    init(error: WebcamCaptureError? = nil) { self.error = error }
    func setError(_ error: WebcamCaptureError?) { self.error = error }
    func start(deviceID: String, operationID _: UInt64) throws -> WebcamPreviewSource {
        started.append(deviceID)
        if let error { throw error }
        return WebcamPreviewSource(session: AVCaptureSession())
    }
    func capture(operationID _: UInt64) throws -> Data { throw WebcamCaptureError.noFrame }
    func stop(operationID _: UInt64) {
        // This fixture has no session resources to tear down.
    }
}

private struct StaticWebcamDevices: WebcamDeviceDiscovering {
    func snapshot() -> WebcamDevices {
        WebcamDevices(devices: [WebcamDevice(id: "preferred", name: "Camera")], defaultID: "preferred")
    }
}

/// A camera discovery fixture that lets tests deliver catalog snapshots out of order.
private actor DelayedWebcamDevices: WebcamDeviceDiscovering {
    private var continuations: [CheckedContinuation<WebcamDevices, Never>] = []

    func snapshot() async -> WebcamDevices { await withCheckedContinuation { continuations.append($0) } }
    func waitForRequests(_ count: Int) async { while continuations.count < count { await Task.yield() } }
    func finish(_ index: Int, id: String) {
        continuations[index].resume(returning: WebcamDevices(devices: [WebcamDevice(id: id, name: id)], defaultID: id))
    }
}
