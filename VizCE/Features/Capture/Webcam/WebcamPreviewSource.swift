@preconcurrency import AVFoundation

/// An opaque camera session reference used to create a main-actor preview layer.
///
/// Session configuration and start/stop operations remain on the capture worker queue.
final class WebcamPreviewSource: @unchecked Sendable {
    private let session: AVCaptureSession?
    /// Wraps a session without exposing it; `nil` creates a source without a preview for test
    /// backends.
    init(session: AVCaptureSession? = nil) { self.session = session }

    /// Creates a centered aspect-fill preview layer on the main actor, or returns `nil` without a
    /// session.
    @MainActor
    func makeLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}
