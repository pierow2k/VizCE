import Foundation

/// Login registration states, including required user approval and an unavailable service.
enum LaunchAtLoginStatus: Sendable, Equatable, CaseIterable {
    // Keep the established status enumeration order used by clients and tests.
    // swiftlint:disable sorted_enum_cases
    case notRegistered, enabled, requiresApproval, notFound
    // swiftlint:enable sorted_enum_cases
}
