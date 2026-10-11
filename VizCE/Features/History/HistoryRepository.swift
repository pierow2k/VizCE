import Combine
import Foundation

/// Main-actor history storage that replays edits made during loading and serializes snapshot saves.
@MainActor
final class HistoryRepository: ObservableObject {
    /// The visible history snapshot, including edits made before loading finishes.
    @Published private(set) var items: [StoredHistoryEntry] = []
    @Published private(set) var isLoading = false
    /// The localized persistence error shown until a load or explicit retry clears it.
    @Published private(set) var failure: String?
    private let store: any HistoryStoring
    /// Whether a disk snapshot has been read successfully, allowing subsequent edits to be saved.
    private var loaded = false
    /// Edits awaiting replay on a successfully loaded snapshot, in application order.
    private var mutations: [HistoryMutation] = []
    // nil means no queued write; an empty snapshot must still persist a history clear.
    /// The newest unsaved snapshot; `nil` means no replacement snapshot is queued.
    private var pending: [StoredHistoryEntry]? // swiftlint:disable:this discouraged_optional_collection
    private var loadTask: Task<Void, Never>?
    /// The sole snapshot drain task, preventing writes from competing with one another.
    private var saveTask: Task<Void, Never>?
    /// The most recent load or save error, retained to pause writes until retry.
    private var lastError: Error?

    /// Creates a repository and immediately schedules loading from the injected store.
    init(store: any HistoryStoring) {
        self.store = store
        load()
    }

    /// Adds a record to visible history and buffers or schedules its persistence.
    func append(_ entry: StoredHistoryEntry) { mutate(.append(entry)) }
    /// Removes all records with the identifier and buffers or schedules the edited snapshot.
    func delete(id: String) { mutate(.delete(id)) }
    /// Clears visible history and buffers or schedules an empty snapshot.
    func clear() { mutate(.clear) }

    /// Applies an edit immediately and queues it for replay until disk history has loaded successfully.
    private func mutate(_ mutation: HistoryMutation) {
        mutation.apply(to: &items)
        if loaded { enqueue() } else { mutations.append(mutation) }
    }

    /// Loads disk history once at a time and replays buffered edits before enabling saves.
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
                for mutation in mutations { mutation.apply(to: &entries) }
                let edited = !mutations.isEmpty
                mutations.removeAll()
                items = entries
                loaded = true
                isLoading = false
                if edited { enqueue() }
            } catch {
                guard let self else { return }
                lastError = error
                failure = String(localized: "Unable to load history: \(error.localizedDescription)")
                isLoading = false
                // Keep edits buffered; never overwrite a file that could not be read.
            }
        }
    }

    /// Replaces the pending snapshot with current items and starts draining unless an error pauses writes.
    private func enqueue() {
        pending = items
        guard lastError == nil else { return }
        drain()
    }

    /// Starts one serial save loop, coalescing pending snapshots and retaining the newest snapshot on failure.
    private func drain() {
        guard saveTask == nil else { return }
        let store = store
        saveTask = Task { [weak self] in
            guard let self else { return }
            while let snapshot = pending {
                pending = nil
                do { try await store.save(snapshot) } catch {
                    // A newer pending snapshot already contains all subsequent edits.
                    if pending == nil { pending = snapshot }
                    lastError = error
                    failure = String(localized: "Unable to save history: \(error.localizedDescription)")
                    break
                }
            }
            saveTask = nil
        }
    }

    /// Retries loading after a read failure, or resumes pending writes after a save failure.
    func retry() {
        if !loaded {
            load()
        } else {
            lastError = nil
            failure = nil
            drain()
        }
    }

    /// Waits for loading and all tracked snapshot saves to finish.
    ///
    /// - Throws: The retained load or save error when persistence has failed.
    func flush() async throws {
        await loadTask?.value
        if let lastError { throw lastError }
        while let task = saveTask { await task.value }
        if let lastError { throw lastError }
    }
}
