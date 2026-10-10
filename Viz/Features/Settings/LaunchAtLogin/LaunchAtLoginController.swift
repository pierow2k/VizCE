import Foundation
import Combine

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var status = LaunchAtLoginStatus.notRegistered
    @Published private(set) var isPending = false
    @Published var errorMessage: String?
    private let service: any LaunchAtLoginServicing
    private var task: Task<Void, Never>?

    init(service: any LaunchAtLoginServicing = SystemLaunchAtLoginService()) {
        self.service = service
        refresh()
    }

    var isEnabled: Bool {
        get { status == .enabled }
        set { request(newValue) }
    }

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

    func waitForPendingOperation() async { await task?.value }
}
