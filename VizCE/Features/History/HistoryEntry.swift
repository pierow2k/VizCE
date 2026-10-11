/// A text or color capture used by the history interface.
enum HistoryEntry: Identifiable, Codable {
    /// A sampled color with its stable identity and formatted values.
    case color(ColorItem)
    /// A recognized text capture with its stable identity.
    case text(TextItem)

    var id: String {
        switch self {
        case .text(let item):
            return item.id

        case .color(let item):
            return item.id
        }
    }
}
