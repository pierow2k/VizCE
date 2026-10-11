import Foundation

/// A main-actor dismissal timer that invalidates callbacks when replaced or canceled.
@MainActor
final class PreviewExpiry {
    /// An injectable main-actor wait that may throw when the caller is canceled.
    typealias Sleep = @MainActor (Duration) async throws -> Void
    private let sleep: Sleep
    private var task: Task<Void, Never>?
    /// The timer generation that invalidates callbacks even when an injected wait ignores cancellation.
    private var generation: UInt64 = 0

    /// Creates an expiry timer with an injectable wait, using cancellable task sleep by default.
    init(sleep: @escaping Sleep = { try await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Replaces the pending timer and calls `close` only if this generation remains current.
    ///
    /// - Parameters:
    ///   - duration: The delay before closing the preview.
    ///   - close: The main-actor action invoked after a successful wait.
    func schedule(after duration: Duration, close: @escaping @MainActor () -> Void) {
        cancel()
        let identity = generation
        let sleep = sleep
        task = Task { @MainActor [weak self] in
            do { try await sleep(duration) } catch { return }
            guard !Task.isCancelled, let self, generation == identity else { return }
            task = nil
            close()
        }
    }

    /// Cancels the pending timer and invalidates its callback.
    func cancel() {
        generation &+= 1
        task?.cancel()
        task = nil
    }

    deinit { task?.cancel() }
}
