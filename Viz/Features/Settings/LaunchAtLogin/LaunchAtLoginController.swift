import Foundation
import Combine

/// Main-actor login registration state that publishes the actual service status after each request.
@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var status = LaunchAtLoginStatus.notRegistered
    /// Whether a status read or registration request is in flight; new operations are ignored until it finishes.
    @Published private(set) var isPending = false
    @Published var errorMessage: String?
    private let service: any LaunchAtLoginServicing
    private var task: Task<Void, Never>?

    /// Creates login state with an injectable service and immediately schedules a status refresh.
    init(service: any LaunchAtLoginServicing = SystemLaunchAtLoginService()) {
        self.service = service
        refresh()
    }

    /// Whether registration is enabled; setting this requests a change rather than optimistically changing status.
    var isEnabled: Bool {
        get { status == .enabled }
        set { request(newValue) }
    }

    /// Reads the actual login service status unless another operation is already pending.
    func refresh() {
        guard !isPending else { return }
        isPending = true
        let service = service
        task = Task { [weak self] in
            let status = await service.status()
            guard let self else { return }
            self.status = status
            self.isPending = false
        }
    }

    /// Requests registration or removal, then publishes actual status even if the service throws.
    ///
    /// Ignores requests while pending and avoids re-registering a service that already awaits approval.
    func request(_ enabled: Bool) {
        guard !isPending else { return }
        isPending = true
        errorMessage = nil
        let service = service
        task = Task { [weak self] in
            let current = await service.status()
            var message: String?
            do {
                if enabled {
                    if current != .enabled && current != .requiresApproval { try await service.register() }
                } else if current == .enabled || current == .requiresApproval {
                    try await service.unregister()
                }
            } catch {
                message = String(localized: "Unable to change launch at login: \(error.localizedDescription)")
            }
            let actual = await service.status()
            guard let self else { return }
            self.status = actual
            self.errorMessage = message
            self.isPending = false
        }
    }

    /// Waits for the currently tracked status refresh or registration request to finish.
    func waitForPendingOperation() async { await task?.value }
}
