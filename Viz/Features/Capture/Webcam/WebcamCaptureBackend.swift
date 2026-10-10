import Foundation

protocol WebcamCaptureBackend: Sendable {
    func start(deviceID: String, operationID: UInt64) async throws -> WebcamPreviewSource
    func capture(operationID: UInt64) async throws -> Data
    func stop(operationID: UInt64) async
}
