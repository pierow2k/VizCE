import Combine
import Foundation

/// Transient copied-row feedback that prevents older expiry tasks from clearing newer feedback.
@MainActor
final class CopyFeedbackController: ObservableObject {
    /// The row showing copy feedback, or `nil` when no confirmation is visible.
    @Published private(set) var copiedID: String?
    private let sleep: @Sendable () async throws -> Void
    private var task: Task<Void, Never>?
    /// The expiry generation that makes callbacks from older copy actions inert.
    private var generation: UInt64 = 0

    /// Creates feedback with an injectable expiry wait, defaulting to one second.
    init(sleep: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(1)) }) {
        self.sleep = sleep
    }

    /// Replaces existing copy feedback and schedules its expiry for the supplied row identifier.
    func show(id: String) {
        clear()
        copiedID = id
        let identity = generation
        let sleep = sleep
        task = Task { [weak self] in
            do { try await sleep() } catch { return }
            guard !Task.isCancelled, let self, generation == identity else { return }
            copiedID = nil
            task = nil
        }
    }

    /// Hides copy feedback and invalidates any pending expiry callback.
    func clear() {
        generation &+= 1
        task?.cancel()
        task = nil
        copiedID = nil
    }
}
