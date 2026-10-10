import Foundation

/// A screen selection result containing owned image bytes, cancellation, or a capture failure.
enum ScreenCaptureOutcome: Sendable, Equatable {
    /// Nonempty encoded bytes read from this capture’s own output file.
    case image(Data)
    case cancelled
    /// A launch or acquisition failure with details for notice presentation.
    case failure(CaptureFailure)
}
