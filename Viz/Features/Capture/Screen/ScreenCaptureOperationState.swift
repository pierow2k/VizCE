import Foundation

/// Mutable fields are accessed only on the owning ScreenCaptureWorker's queue.
final class ScreenCaptureOperationState: @unchecked Sendable {
    var process: Process?
    var cancelled = false
    var finished = false
}
