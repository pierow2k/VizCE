import Foundation

/// A recognition result that distinguishes captured content, an empty result, cancellation, and failure.
enum RecognitionOutcome: Sendable, Equatable {
    case cancelled
    /// Recognized text and barcode payloads suitable for clipboard delivery.
    case content(String)
    /// A recognition or acquisition failure to present when the capture is current.
    case failure(CaptureFailure)
    case noContent
}
