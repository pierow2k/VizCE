import Foundation

/// An immutable snapshot of recognition and delivery preferences for one capture.
struct RecognitionOptions: Sendable {
    /// Whether the worker uses the fast Vision recognition level instead of accurate.
    let fast: Bool
    /// The selected Vision language code, or `nil` to use the request’s default language handling.
    let languageCode: String?
    let keepLineBreaks: Bool
    /// Whether delivery adds this text capture to the current clipboard collection.
    let append: Bool
    let processing: Bool
    /// The shell template evaluated after delivery when `processing` is enabled.
    let commandTemplate: String
}
