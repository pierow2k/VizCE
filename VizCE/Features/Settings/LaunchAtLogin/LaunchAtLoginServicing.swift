import Foundation

/// An asynchronous boundary for observing and changing application login registration.
protocol LaunchAtLoginServicing: Sendable {
    /// Reads the actual service registration state without changing it.
    func status() async -> LaunchAtLoginStatus
    /// Requests login registration or throws a service error.
    func register() async throws
    /// Removes login registration or throws a service error.
    func unregister() async throws
}
