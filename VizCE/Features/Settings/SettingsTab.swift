/// Stable integer identifiers persisted in the selected-settings-tab preference.
enum SettingsTab: Int, CaseIterable {
    // Keep the established tab order and persisted numeric selection values.
    // swiftlint:disable sorted_enum_cases
    case general = 0
    case shortcuts = 1
    case updates = 2
    case about = 3
    // swiftlint:enable sorted_enum_cases
}
