import Foundation

/// Login registration states, including required user approval and an unavailable service.
enum LaunchAtLoginStatus: Sendable, Equatable, CaseIterable {
    case notRegistered, enabled, requiresApproval, notFound
}
