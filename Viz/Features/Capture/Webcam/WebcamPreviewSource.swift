@preconcurrency import AVFoundation

// Only an opaque session reference crosses the worker queue. Configuration and
// start/stop remain queue-confined; AVFoundation connects the main-actor layer
// to that session internally. The wrapper never exposes the session to callers.
final class WebcamPreviewSource: @unchecked Sendable {
    private let session: AVCaptureSession?
    init(session: AVCaptureSession? = nil) { self.session = session }

    @MainActor
    func makeLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}
