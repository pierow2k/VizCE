import Foundation

/// A main-actor generation counter for rejecting results from superseded operations.
@MainActor
final class OperationIdentity {
    /// A wrapping generation counter; tokens are meaningful only within this instance.
    private var generation: UInt64 = 0

    /// Invalidates earlier tokens and returns the new current generation.
    @discardableResult
    func advance() -> UInt64 {
        generation &+= 1
        return generation
    }

    func isCurrent(_ token: UInt64) -> Bool { token == generation }
}
