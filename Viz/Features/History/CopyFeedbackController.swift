import Foundation
import Combine

@MainActor
final class CopyFeedbackController: ObservableObject {
    @Published private(set) var copiedID: String?
    private let sleep: @Sendable () async throws -> Void
    private var task: Task<Void, Never>?
    private var generation: UInt64 = 0

    init(sleep: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(1)) }) {
        self.sleep = sleep
    }

    func show(id: String) {
        clear()
        copiedID = id
        let identity = generation
        let sleep = sleep
        task = Task { [weak self] in
            do { try await sleep() } catch { return }
            guard !Task.isCancelled, let self, self.generation == identity else { return }
            self.copiedID = nil
            self.task = nil
        }
    }

    func clear() {
        generation &+= 1
        task?.cancel()
        task = nil
        copiedID = nil
    }
}
