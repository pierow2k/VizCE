import AppKit
import AVFoundation
import Combine

/// Main-actor camera state that gates asynchronous authorization, startup, and capture by generation.
@MainActor
final class WebcamCaptureCoordinator: ObservableObject {
    /// The published still image with point dimensions set to its pixel dimensions when available.
    @Published private(set) var capturedImage: NSImage?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    @Published private(set) var state = WebcamState.idle
    var isPreviewActive: Bool { state == .previewing }
    var isStarting: Bool { state.isStarting }
    var permissionDenied: Bool { state == .permissionDenied }
    /// The main-actor callback invoked after a current capture is decoded and its preview session is stopped.
    var onCapture: (@MainActor (NSImage) -> Void)?

    private let authorization: any WebcamAuthorizing
    private let backend: any WebcamCaptureBackend
    private let devices: any WebcamDeviceDiscovering
    private let identity = OperationIdentity()
    /// The active operation generation; zero precedes the first camera start.
    private var currentID: UInt64 = 0
    /// The last requested camera, used to coalesce duplicate starts during startup, preview, or capture.
    private var requestedDeviceID: String?
    /// The latest startup, capture, or stop task, canceled when an operation supersedes it.
    private var task: Task<Void, Never>?

    /// Creates camera state with injectable permission, capture, and device discovery services.
    ///
    /// - Parameters:
    ///   - authorization: Checks or requests access to video capture.
    ///   - backend: Owns camera sessions and still-frame acquisition.
    ///   - devices: Resolves the preferred camera when the saved selection is empty.
    init(
        authorization: any WebcamAuthorizing = SystemWebcamAuthorization(),
        backend: any WebcamCaptureBackend = WebcamCaptureWorker(),
        devices: any WebcamDeviceDiscovering = SystemWebcamDeviceCatalog.shared
    ) {
        self.authorization = authorization
        self.backend = backend
        self.devices = devices
    }

    /// Replaces camera startup, stops the previous generation, and publishes only the current result.
    ///
    /// An identical active request is ignored. A nonempty missing camera identifier is
    /// passed through rather than silently replaced with the default.
    ///
    /// - Parameter deviceID: The requested camera identifier, or an empty string to resolve the preferred default.
    func start(deviceID: String) {
        guard !isDuplicateStart(deviceID: deviceID) else { return }
        requestedDeviceID = deviceID
        let previousID = currentID
        task?.cancel()
        currentID = identity.advance()
        let id = currentID
        let backend = backend
        let authorization = authorization
        previewLayer = nil
        capturedImage = nil
        state = .authorizing
        task = Task { @MainActor [weak self] in
            await backend.stop(operationID: previousID)
            guard self?.canPublish(operationID: id) == true else { return }
            let authorized = await authorization.isAuthorized()
            guard let self, canPublish(operationID: id) else { return }
            guard authorized else {
                state = .permissionDenied
                return
            }
            await startAuthorizedPreview(deviceID: deviceID, operationID: id)
        }
    }

    /// Coalesces the same device only while its startup, preview, or still capture remains active.
    private func isDuplicateStart(deviceID: String) -> Bool {
        requestedDeviceID == deviceID && (isStarting || isPreviewActive || state == .capturing)
    }

    /// Allows publication only from the uncanceled task for the current camera generation.
    ///
    /// Call after each suspension before changing UI state or starting another backend operation.
    private func canPublish(operationID: UInt64) -> Bool {
        !Task.isCancelled && identity.isCurrent(operationID)
    }

    /// Resolves an empty selection to the preferred default without replacing explicit missing devices.
    ///
    /// An empty result is passed to the backend when the catalog has no default camera.
    private func resolvedDeviceID(_ deviceID: String) async -> String {
        guard deviceID.isEmpty else { return deviceID }
        return await devices.snapshot().defaultID ?? ""
    }

    /// Starts an authorized generation and publishes its preview or failure only while it remains current.
    ///
    /// A successful stale startup is stopped before returning to release its session.
    ///
    /// - Parameters:
    ///   - deviceID: The selected camera identifier, or an empty string to resolve the default.
    ///   - operationID: The authorized generation whose results may be published.
    private func startAuthorizedPreview(deviceID: String, operationID: UInt64) async {
        do {
            let resolvedID = await resolvedDeviceID(deviceID)
            guard canPublish(operationID: operationID) else { return }
            state = .starting
            let source = try await backend.start(deviceID: resolvedID, operationID: operationID)
            guard canPublish(operationID: operationID) else {
                await backend.stop(operationID: operationID)
                return
            }
            previewLayer = source.makeLayer()
            state = .previewing
        } catch {
            guard canPublish(operationID: operationID) else { return }
            state = .failed(error.localizedDescription)
        }
    }

    /// Captures the active preview frame, stops its session, and publishes a still image or recovery failure.
    ///
    /// Has no effect outside the previewing state; superseded results are discarded.
    func capturePhoto() {
        guard isPreviewActive else { return }
        state = .capturing
        let id = currentID
        let backend = backend
        task?.cancel()
        task = Task { @MainActor [weak self] in
            do {
                let data = try await backend.capture(operationID: id)
                guard !Task.isCancelled, let self, identity.isCurrent(id) else { return }
                guard let image = NSImage(data: data) else {
                    throw WebcamCaptureError.conversionFailed
                }
                if let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    image.size = NSSize(width: pixels.width, height: pixels.height)
                }
                await backend.stop(operationID: id)
                guard !Task.isCancelled, identity.isCurrent(id) else { return }
                previewLayer = nil
                state = .captured
                capturedImage = image
                onCapture?(image)
            } catch {
                guard !Task.isCancelled, let self, identity.isCurrent(id) else { return }
                await backend.stop(operationID: id)
                guard !Task.isCancelled, identity.isCurrent(id) else { return }
                previewLayer = nil
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// Invalidates pending publication, clears the preview, and asynchronously stops the previous session.
    ///
    /// The captured still image is retained until a subsequent start clears it.
    func stop() {
        let previousID = currentID
        currentID = identity.advance()
        task?.cancel()
        previewLayer = nil
        state = .idle
        let backend = backend
        task = Task { await backend.stop(operationID: previousID) }
    }

    /// Requests startup for the selected device, using the same duplicate-request rules as `start(deviceID:)`.
    func restart(deviceID: String) { start(deviceID: deviceID) }

    /// Waits for the currently tracked startup, capture, or stop task to finish.
    func waitForPendingOperation() async { await task?.value }
}
