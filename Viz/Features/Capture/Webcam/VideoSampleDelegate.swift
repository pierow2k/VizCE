@preconcurrency import AVFoundation

final class VideoSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private weak var worker: WebcamCaptureWorker?
    init(worker: WebcamCaptureWorker) { self.worker = worker }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        worker?.receive(sampleBuffer, from: output)
    }
}
