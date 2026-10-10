import Foundation

extension Bundle {

    /// The display name, falling back to the bundle name and then `"N/A"`.
    var name: String {
        func string(for key: String) -> String? {
            object(forInfoDictionaryKey: key) as? String
        }
        return string(for: "CFBundleDisplayName")
        ?? string(for: "CFBundleName")
        ?? "N/A"
    }
}

extension Bundle {

    /// The short release version from bundle metadata, or `"N/A"` when absent.
    var version: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    /// The build version from bundle metadata, or `"N/A"` when absent.
    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
