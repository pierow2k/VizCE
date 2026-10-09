import Foundation
import Combine

/// Buffers edits during loading and owns exactly one drain of immutable snapshots.
@MainActor
final class HistoryRepository: ObservableObject {
    @Published private(set) var items: [StoredHistoryEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var failure: String?
    private let store: any HistoryStoring
    private var loaded = false
    private var mutations: [HistoryMutation] = []
    private var pending: [StoredHistoryEntry]?
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var lastError: Error?

    init(store: any HistoryStoring) {
        self.store = store
        load()
    }

    func append(_ entry: StoredHistoryEntry) { mutate(.append(entry)) }
    func delete(id: String) { mutate(.delete(id)) }
    func clear() { mutate(.clear) }

    private func mutate(_ mutation: HistoryMutation) {
        mutation.apply(to: &items)
        if loaded { enqueue() }
        else { mutations.append(mutation) }
    }

    private func load() {
        guard !isLoading else { return }
        isLoading = true
        failure = nil
        lastError = nil
        let store = store
        loadTask = Task { [weak self] in
            do {
                var entries = try await store.load()
                guard let self else { return }
                for mutation in self.mutations { mutation.apply(to: &entries) }
                let edited = !self.mutations.isEmpty
                self.mutations.removeAll()
                self.items = entries
                self.loaded = true
                self.isLoading = false
                if edited { self.enqueue() }
            } catch {
                guard let self else { return }
                self.lastError = error
                self.failure = String(localized: "Unable to load history: \(error.localizedDescription)")
                self.isLoading = false
                // Keep edits buffered; never overwrite a file that could not be read.
            }
        }
    }

    private func enqueue() {
        pending = items
        guard lastError == nil else { return }
        drain()
    }

    private func drain() {
        guard saveTask == nil else { return }
        let store = store
        saveTask = Task { [weak self] in
            guard let self else { return }
            while let snapshot = self.pending {
                self.pending = nil
                do { try await store.save(snapshot) }
                catch {
                    // A newer pending snapshot already contains all subsequent edits.
                    if self.pending == nil { self.pending = snapshot }
                    self.lastError = error
                    self.failure = String(localized: "Unable to save history: \(error.localizedDescription)")
                    break
                }
            }
            self.saveTask = nil
        }
    }

    func retry() {
        if !loaded { load() }
        else {
            lastError = nil
            failure = nil
            drain()
        }
    }

    func flush() async throws {
        await loadTask?.value
        if let lastError { throw lastError }
        while let task = saveTask { await task.value }
        if let lastError { throw lastError }
    }
}
