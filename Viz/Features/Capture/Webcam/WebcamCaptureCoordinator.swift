import AVFoundation
import AppKit
import Combine

@MainActor
final class WebcamCaptureCoordinator: ObservableObject {
    @Published private(set) var capturedImage: NSImage?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    @Published private(set) var state = WebcamState.idle
    var isPreviewActive: Bool { state == .previewing }
    var isStarting: Bool { state.isStarting }
    var permissionDenied: Bool { state == .permissionDenied }
    var onCapture: (@MainActor (NSImage) -> Void)?

    private let authorization: any WebcamAuthorizing
    private let backend: any WebcamCaptureBackend
    private let devices: any WebcamDeviceDiscovering
    private let identity = OperationIdentity()
    private var currentID: UInt64 = 0
    private var requestedDeviceID: String?
    private var task: Task<Void, Never>?

    init(
        authorization: any WebcamAuthorizing = SystemWebcamAuthorization(),
        backend: any WebcamCaptureBackend = WebcamCaptureWorker(),
        devices: any WebcamDeviceDiscovering = SystemWebcamDeviceCatalog.shared
    ) {
        self.authorization = authorization
        self.backend = backend
        self.devices = devices
    }

    func start(deviceID: String) {
        guard
            requestedDeviceID != deviceID
                || (!isStarting && !isPreviewActive && state != .capturing)
        else { return }
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
        let devices = devices
        task = Task { @MainActor [weak self] in
            await backend.stop(operationID: previousID)
            guard !Task.isCancelled, self?.identity.isCurrent(id) == true else { return }
            let authorized = await authorization.isAuthorized()
            guard !Task.isCancelled, let self, self.identity.isCurrent(id) else { return }
            guard authorized else {
                self.state = .permissionDenied
                return
            }
            do {
                let resolvedID: String
                if deviceID.isEmpty {
                    resolvedID = await devices.snapshot().defaultID ?? ""
                } else {
                    resolvedID = deviceID
                }
                guard !Task.isCancelled, self.identity.isCurrent(id) else { return }
                self.state = .starting
                let source = try await backend.start(deviceID: resolvedID, operationID: id)
                guard !Task.isCancelled, self.identity.isCurrent(id) else {
                    await backend.stop(operationID: id)
                    return
                }
                self.previewLayer = source.makeLayer()
                self.state = .previewing
            } catch {
                guard !Task.isCancelled, self.identity.isCurrent(id) else { return }
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    func capturePhoto() {
        guard isPreviewActive else { return }
        state = .capturing
        let id = currentID
        let backend = backend
        task?.cancel()
        task = Task { @MainActor [weak self] in
            do {
                let data = try await backend.capture(operationID: id)
                guard !Task.isCancelled, let self, self.identity.isCurrent(id) else { return }
                guard let image = NSImage(data: data) else {
                    throw WebcamCaptureError.conversionFailed
                }
                if let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    image.size = NSSize(width: pixels.width, height: pixels.height)
                }
                await backend.stop(operationID: id)
                guard !Task.isCancelled, self.identity.isCurrent(id) else { return }
                self.previewLayer = nil
                self.state = .captured
                self.capturedImage = image
                self.onCapture?(image)
            } catch {
                guard !Task.isCancelled, let self, self.identity.isCurrent(id) else { return }
                await backend.stop(operationID: id)
                guard !Task.isCancelled, self.identity.isCurrent(id) else { return }
                self.previewLayer = nil
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    func stop() {
        let previousID = currentID
        currentID = identity.advance()
        task?.cancel()
        previewLayer = nil
        state = .idle
        let backend = backend
        task = Task { await backend.stop(operationID: previousID) }
    }

    func restart(deviceID: String) { start(deviceID: deviceID) }

    func waitForPendingOperation() async { await task?.value }
}
