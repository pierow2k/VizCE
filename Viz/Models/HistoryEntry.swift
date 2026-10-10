enum HistoryEntry: Identifiable, Codable {
    case text(TextItem)
    case color(ColorItem)

    var id: String {
        switch self {
        case .text(let item): return item.id
        case .color(let item): return item.id
        }
    }
}
