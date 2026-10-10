import Foundation

/// Localized display names for Vision language codes, with a Vietnamese identifier correction.
struct RecognitionLanguageName {
    /// Returns a localized language name, correcting `vi-VT` to `vi-VN` only for display.
    ///
    /// - Parameters:
    ///   - code: The original Vision identifier, retained as the fallback label.
    ///   - locale: The locale used to resolve the display name.
    static func displayName(for code: String, locale: Locale) -> String {
        let identifier = code == "vi-VT" ? "vi-VN" : code
        return locale.localizedString(forIdentifier: identifier) ?? code
    }
}
