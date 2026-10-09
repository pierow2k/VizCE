import Foundation

/// Main-actor publication gate for replaceable asynchronous operations.
@MainActor
final class OperationIdentity {
    private var generation: UInt64 = 0

    @discardableResult
    func advance() -> UInt64 {
        generation &+= 1
        return generation
    }

    func isCurrent(_ token: UInt64) -> Bool { token == generation }
}
