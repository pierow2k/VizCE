/// The user-selectable Vision recognition level stored under its display name.
enum TextRecognitionQuality: String, CaseIterable, Identifiable {
    // Keep the established Fast, Accurate enumeration order.
    // swiftlint:disable sorted_enum_cases
    case fast = "Fast"
    case accurate = "Accurate"
    // swiftlint:enable sorted_enum_cases

    var id: String { self.rawValue }
}
