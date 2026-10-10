import Foundation

enum LaunchAtLoginStatus: Sendable, Equatable, CaseIterable {
    case notRegistered, enabled, requiresApproval, notFound
}
