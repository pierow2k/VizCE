import Foundation
import Combine

@MainActor
final class RecognitionLanguageSelection: ObservableObject {
    @Published private(set) var codes: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var failure: String?
    private let catalog: RecognitionLanguageCatalog
    private var task: Task<Void, Never>?
    private var generation: UInt64 = 0

    init(catalog: RecognitionLanguageCatalog = .shared) { self.catalog = catalog }

    func load(_ configuration: RecognitionConfiguration) {
        generation &+= 1
        let id = generation
        task?.cancel()
        codes = []
        isLoading = true
        failure = nil
        let catalog = catalog
        task = Task { [weak self] in
            do {
                let codes = try await catalog.codes(for: configuration)
                guard !Task.isCancelled, let self, self.generation == id else { return }
                self.codes = codes
                self.isLoading = false
            } catch {
                guard !Task.isCancelled, let self, self.generation == id else { return }
                self.failure = String(localized: "Unable to load recognition languages: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }

    func waitForLoad() async { await task?.value }
}
