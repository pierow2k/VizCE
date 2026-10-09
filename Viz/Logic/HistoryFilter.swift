import Foundation

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all, text, colors
    var id: Self { self }
    var title: LocalizedStringResource {
        switch self {
        case .all: "All"
        case .text: "Text"
        case .colors: "Colors"
        }
    }
    var emptyMessage: LocalizedStringResource {
        switch self {
        case .all: "No items have been captured"
        case .text: "No text has been captured"
        case .colors: "No colors have been captured"
        }
    }
    func includes(isText: Bool) -> Bool {
        switch self {
        case .all: true
        case .text: isText
        case .colors: !isText
        }
    }
}
