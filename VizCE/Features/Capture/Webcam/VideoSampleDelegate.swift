@preconcurrency import AVFoundation

/// A video callback bridge that weakly references the queue-confined capture worker.
final class VideoSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private weak var worker: WebcamCaptureWorker?
    /// Creates a delegate that forwards video frames without retaining the worker.
    init(worker: WebcamCaptureWorker) { self.worker = worker }

    /// Forwards a video frame to the worker on the queue configured for the video output delegate.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from _: AVCaptureConnection) {
        worker?.receive(sampleBuffer, from: output)
    }
}
