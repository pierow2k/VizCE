import Foundation

protocol LaunchAtLoginServicing: Sendable {
    func status() async -> LaunchAtLoginStatus
    func register() async throws
    func unregister() async throws
}
