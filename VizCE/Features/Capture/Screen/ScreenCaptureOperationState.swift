import Foundation

/// Mutable subprocess state confined to its owning screen capture worker queue.
final class ScreenCaptureOperationState: @unchecked Sendable {
    var process: Process?
    var cancelled = false
    /// Whether lifecycle cleanup has completed, so late cancellation must not terminate the
    /// process.
    var finished = false
}
