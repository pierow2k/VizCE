/// The user-selectable Vision recognition level stored under its display name.
enum TextRecognitionQuality: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case accurate = "Accurate"

    var id: String { self.rawValue }
}
