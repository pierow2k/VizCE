import Foundation

/// Capture-time values: workers never consult mutable UI models or preferences.
struct RecognitionOptions: Sendable {
    let fast: Bool
    let languageCode: String?
    let keepLineBreaks: Bool
    let append: Bool
    let processing: Bool
    let commandTemplate: String
}
