@preconcurrency import AVFoundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// A camera backend with session operations, callbacks, sample buffers, and encoding confined to one queue.
///
/// Only encoded image data and an opaque preview source cross that queue boundary.
final class WebcamCaptureWorker: WebcamCaptureBackend, @unchecked Sendable {
    private let queue = DispatchQueue(label: "VizCE.webcam.capture", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var delegate: VideoSampleDelegate?
    /// The latest frame from the current output, retained and read only on the worker queue.
    private var sampleBuffer: CMSampleBuffer?
    /// The current session generation, or `nil` when no session is configured.
    private var operationID: UInt64?
    /// The oldest generation allowed to start, advanced by stops even if startup has not reached the queue.
    private var minimumOperationID: UInt64 = 0
    private lazy var context = CIContext()

    /// Configures and starts the requested camera on the worker queue after rejecting invalidated generations.
    ///
    /// - Parameters:
    ///   - deviceID: A camera identifier, or an empty string for the system default.
    ///   - operationID: The generation that must meet the worker’s current minimum.
    /// - Returns: An opaque preview source for the running session.
    /// - Throws: Camera setup, startup, or stale-operation errors.
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

    /// Encodes the latest buffered frame as PNG when the requested generation owns the session.
    ///
    /// - Throws: A stale-operation, missing-frame, or image-conversion error.
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

    /// Invalidates starts through the supplied generation and tears down any session no newer than it.
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

    /// Retains the newest frame only when it comes from the current output.
    ///
    /// Must be called on the worker queue configured for the video delegate.
    ///
    /// - Parameters:
    ///   - buffer: The latest video sample to retain for a still capture.
    ///   - output: The originating output, checked against the active session output.
    func receive(_ buffer: CMSampleBuffer, from output: AVCaptureOutput) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard output === self.output else { return }
        sampleBuffer = buffer
    }

    /// Adds the selected camera and video output with callbacks on the worker queue.
    ///
    /// Must run on the worker queue; configuration commits even if adding an input or output fails.
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

    /// Converts the retained video frame to immutable PNG bytes on the worker queue.
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

    /// Stops the session and detaches inputs, outputs, callbacks, and the buffered frame on the worker queue.
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
