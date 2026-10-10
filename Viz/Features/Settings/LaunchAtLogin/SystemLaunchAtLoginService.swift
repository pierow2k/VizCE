import ServiceManagement

/// An actor that adapts the main application login service to observable registration states.
actor SystemLaunchAtLoginService: LaunchAtLoginServicing {
    /// Maps the system main-app registration state, treating unknown states as unavailable.
    func status() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .notRegistered: .notRegistered
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        @unknown default: .notFound
        }
    }
    /// Requests main-app login registration and propagates service errors.
    func register() throws { try SMAppService.mainApp.register() }
    /// Removes main-app login registration and propagates service errors.
    func unregister() async throws { try await SMAppService.mainApp.unregister() }
}
