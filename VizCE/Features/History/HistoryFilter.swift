import Foundation

/// Capture-kind filters and their corresponding history labels and empty messages.
enum HistoryFilter: String, CaseIterable, Identifiable {
    // Keep menu order and explicit stable raw values; the redundant-value rule conflicts with
    // explicit_enum_raw_value.
    // swiftlint:disable sorted_enum_cases redundant_string_enum_value
    case all = "all"
    case text = "text"
    case colors = "colors"
    // swiftlint:enable sorted_enum_cases redundant_string_enum_value

    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .all:
            "All"

        case .text:
            "Text"

        case .colors:
            "Colors"
        }
    }
    var emptyMessage: LocalizedStringResource {
        switch self {
        case .all:
            "No items have been captured"

        case .text:
            "No text has been captured"

        case .colors:
            "No colors have been captured"
        }
    }
    /// Tests whether a capture kind belongs in this filter; `false` identifies a color capture.
    func includes(isText: Bool) -> Bool {
        switch self {
        case .all:
            true

        case .text:
            isText

        case .colors:
            !isText
        }
    }
}
