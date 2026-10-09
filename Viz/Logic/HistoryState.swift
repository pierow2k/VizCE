import Foundation
import Combine
import AlinFoundation

@MainActor
final class HistoryState: ObservableObject {
    static let shared = HistoryState()
    @Published private(set) var historyItems: [HistoryEntry] = []
    let repository: HistoryRepository
    private var subscriptions: Set<AnyCancellable> = []

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

    func append(_ entry: HistoryEntry) {
        switch entry {
        case .text(let item): repository.append(.text(StoredTextItem(id: item.id, text: item.text)))
        case .color(let item): repository.append(.color(StoredColorItem(id: item.id, hex: item.hex, rgb: item.rgb)))
        }
    }
    func delete(id: String) { repository.delete(id: id) }
    func clear() { repository.clear() }
    func flush() async throws { try await repository.flush() }
}
