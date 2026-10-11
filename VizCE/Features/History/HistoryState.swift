import AlinFoundation
import Combine
import Foundation

/// Main-actor adaptation of immutable stored records into the history interface models.
@MainActor
final class HistoryState: ObservableObject {
    static let shared = HistoryState()
    @Published private(set) var historyItems: [HistoryEntry] = []
    let repository: HistoryRepository
    private var subscriptions: Set<AnyCancellable> = []

    /// Observes stored history and republishes it as text and color interface models.
    ///
    /// - Parameter repository: An injected repository, or `nil` to load the application support history file.
    init(repository: HistoryRepository? = nil) {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Bundle.main.name).appendingPathComponent("historyItems.json")
        self.repository = repository ?? HistoryRepository(store: HistoryFileStore(url: url))
        self.repository.$items.sink { [weak self] records in
            self?.historyItems = records.map { record in
                switch record {
                case .text(let value): .text(TextItem(id: value.id, text: value.text))
                case .color(let value): .color(ColorItem(hex: value.hex, rgb: value.rgb, id: value.id))
                }
            }
        }.store(in: &subscriptions)
        self.repository.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &subscriptions)
    }

    /// Snapshots a text or color interface model and appends it to the persistent repository.
    func append(_ entry: HistoryEntry) {
        switch entry {
        case .text(let item): repository.append(.text(StoredTextItem(id: item.id, text: item.text)))
        case .color(let item): repository.append(.color(StoredColorItem(id: item.id, hex: item.hex, rgb: item.rgb)))
        }
    }
    /// Deletes repository records with the supplied stable identifier.
    func delete(id: String) { repository.delete(id: id) }
    /// Clears repository history and schedules persistence of the change.
    func clear() { repository.clear() }
    /// Waits for repository persistence and propagates any retained load or save error.
    func flush() async throws { try await repository.flush() }
}
