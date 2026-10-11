import Combine

/// Main-actor text captures currently available for preview and clipboard appending.
@MainActor
final class RecognizedContent: ObservableObject {
    static let shared = RecognizedContent()
    @Published var items = [TextItem]()
}
