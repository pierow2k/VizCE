import Foundation

struct RecognitionLanguageName {
    static func displayName(for code: String, locale: Locale) -> String {
        let identifier = code == "vi-VT" ? "vi-VN" : code
        return locale.localizedString(forIdentifier: identifier) ?? code
    }
}
