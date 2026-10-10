import Combine

@MainActor
final class RecognizedContent: ObservableObject {
    static let shared = RecognizedContent()
    @Published var items = [TextItem]()
}
