@preconcurrency import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

// Safety boundary: all mutable state, session operations, delegate callbacks,
// sample buffers, and image conversion are confined to queue. Only immutable
// encoded image data and the opaque preview source leave it. No buffer reaches UI.
final class WebcamCaptureWorker: WebcamCaptureBackend, @unchecked Sendable {
    private let queue = DispatchQueue(label: "Viz.webcam.capture", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var delegate: VideoSampleDelegate?
    private var sampleBuffer: CMSampleBuffer?
    private var operationID: UInt64?
    private var minimumOperationID: UInt64 = 0
    private lazy var context = CIContext()

    func start(deviceID: String, operationID: UInt64) async throws -> WebcamPreviewSource {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard operationID >= self.minimumOperationID else {
                    continuation.resume(throwing: WebcamCaptureError.staleOperation)
                    return
                }
                self.minimumOperationID = operationID
                self.tearDown()
                do {
                    let device = deviceID.isEmpty ? AVCaptureDevice.default(for: .video) : AVCaptureDevice(uniqueID: deviceID)
                    guard let device else { throw WebcamCaptureError.noDevice }
                    let session = AVCaptureSession()
                    self.session = session
                    self.operationID = operationID
                    try self.configure(session, device: device)
                    session.startRunning()
                    guard session.isRunning else { throw WebcamCaptureError.startFailed }
                    continuation.resume(returning: WebcamPreviewSource(session: session))
                } catch {
                    self.tearDown()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func capture(operationID: UInt64) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    guard self.operationID == operationID else { throw WebcamCaptureError.staleOperation }
                    guard let buffer = self.sampleBuffer else { throw WebcamCaptureError.noFrame }
                    continuation.resume(returning: try self.encodeFrame(buffer))
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    func stop(operationID: UInt64) async {
        await withCheckedContinuation { continuation in
            queue.async {
                // Invalidate even a start that has not reached this queue yet.
                self.minimumOperationID = max(self.minimumOperationID, operationID &+ 1)
                if let activeID = self.operationID, activeID <= operationID { self.tearDown() }
                continuation.resume()
            }
        }
    }

    func receive(_ buffer: CMSampleBuffer, from output: AVCaptureOutput) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard output === self.output else { return }
        sampleBuffer = buffer
    }

    private func configure(_ session: AVCaptureSession, device: AVCaptureDevice) throws {
        dispatchPrecondition(condition: .onQueue(queue))
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw WebcamCaptureError.unsupportedInput }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) else { throw WebcamCaptureError.unsupportedOutput }
        let delegate = VideoSampleDelegate(worker: self)
        self.output = output
        self.delegate = delegate
        output.setSampleBufferDelegate(delegate, queue: queue)
        session.addOutput(output)
    }

    private func encodeFrame(_ buffer: CMSampleBuffer) throws -> Data {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let pixels = CMSampleBufferGetImageBuffer(buffer) else { throw WebcamCaptureError.noFrame }
        let image = CIImage(cvImageBuffer: pixels)
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw WebcamCaptureError.conversionFailed
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw WebcamCaptureError.conversionFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { throw WebcamCaptureError.conversionFailed }
        return data as Data
    }

    private func tearDown() {
        dispatchPrecondition(condition: .onQueue(queue))
        output?.setSampleBufferDelegate(nil, queue: nil)
        session?.stopRunning()
        if let session {
            session.beginConfiguration()
            for input in session.inputs { session.removeInput(input) }
            for output in session.outputs { session.removeOutput(output) }
            session.commitConfiguration()
        }
        sampleBuffer = nil
        delegate = nil
        output = nil
        session = nil
        operationID = nil
    }
}
