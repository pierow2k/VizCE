import Combine
import Foundation

/// Main-actor language picker state that rejects results from earlier quality selections.
@MainActor
final class RecognitionLanguageSelection: ObservableObject {
    @Published private(set) var codes: [String] = []
    @Published private(set) var isLoading = false
    /// The localized discovery error, cleared whenever a replacement load begins.
    @Published private(set) var failure: String?
    private let catalog: RecognitionLanguageCatalog
    private var task: Task<Void, Never>?
    /// The load generation that prevents earlier discovery results from replacing the current selection.
    private var generation: UInt64 = 0

    /// Creates language selection state using the supplied shared discovery catalog.
    init(catalog: RecognitionLanguageCatalog = .shared) { self.catalog = catalog }

    /// Replaces the visible language query and publishes only this generation’s result or error.
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
                guard !Task.isCancelled, let self, generation == id else { return }
                self.codes = codes
                isLoading = false
            } catch {
                guard !Task.isCancelled, let self, generation == id else { return }
                failure = String(localized: "Unable to load recognition languages: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    /// Waits for the currently tracked language load, including its state publication.
    func waitForLoad() async { await task?.value }
}
