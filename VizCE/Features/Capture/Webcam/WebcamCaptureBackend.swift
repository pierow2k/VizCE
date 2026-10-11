import Foundation

/// A camera session boundary whose operations are identified by monotonically increasing generations.
protocol WebcamCaptureBackend: Sendable {
    /// Starts a preview session for a camera and operation generation.
    ///
    /// - Parameters:
    ///   - deviceID: The selected camera identifier, or an empty string for the system default.
    ///   - operationID: The monotonically increasing generation used to reject superseded operations.
    /// - Returns: An opaque session source from which a main-actor preview layer can be created.
    /// - Throws: Camera setup or stale-operation errors.
    func start(deviceID: String, operationID: UInt64) async throws -> WebcamPreviewSource
    /// Returns encoded still-image bytes from the requested operation, or throws a capture error.
    func capture(operationID: UInt64) async throws -> Data
    /// Stops sessions no newer than the supplied generation and invalidates starts through that generation.
    func stop(operationID: UInt64) async
}
