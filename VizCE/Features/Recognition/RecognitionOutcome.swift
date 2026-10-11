import Foundation

/// A recognition result that distinguishes captured content, an empty result, cancellation, and failure.
enum RecognitionOutcome: Sendable, Equatable {
    /// Recognized text and barcode payloads suitable for clipboard delivery.
    case content(String)
    case noContent
    case cancelled
    /// A recognition or acquisition failure to present when the capture is current.
    case failure(CaptureFailure)
}
