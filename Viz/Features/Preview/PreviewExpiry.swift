import Foundation

@MainActor
final class PreviewExpiry {
    typealias Sleep = @MainActor (Duration) async throws -> Void
    private let sleep: Sleep
    private var task: Task<Void, Never>?
    private var generation: UInt64 = 0

    init(sleep: @escaping Sleep = { try await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    func schedule(after duration: Duration, close: @escaping @MainActor () -> Void) {
        cancel()
        let identity = generation
        let sleep = sleep
        task = Task { @MainActor [weak self] in
            do { try await sleep(duration) }
            catch { return }
            guard !Task.isCancelled, let self, self.generation == identity else { return }
            self.task = nil
            close()
        }
    }

    func cancel() {
        generation &+= 1
        task?.cancel()
        task = nil
    }

    deinit { task?.cancel() }
}
