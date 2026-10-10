import Combine
import Foundation

/// Main-actor camera choices that publish only the latest device discovery result.
@MainActor
final class WebcamManager: ObservableObject {
    @Published private(set) var availableDevices: [WebcamDevice] = []
    @Published private(set) var defaultDevice: WebcamDevice?
    private let provider: any WebcamDeviceDiscovering
    private var task: Task<Void, Never>?
    /// The refresh generation used to reject earlier device discovery completions.
    private var generation: UInt64 = 0

    /// Creates camera choices with an injected discovery provider and immediately starts a refresh.
    init(provider: any WebcamDeviceDiscovering = SystemWebcamDeviceCatalog.shared) {
        self.provider = provider
        refresh()
    }

    /// Replaces the pending device query and publishes only the latest discovery snapshot.
    func refresh() {
        task?.cancel()
        generation &+= 1
        let id = generation
        let provider = provider
        task = Task { [weak self] in
            let snapshot = await provider.snapshot()
            guard !Task.isCancelled, let self, self.generation == id else { return }
            self.availableDevices = snapshot.devices
            self.defaultDevice = snapshot.defaultDevice
        }
    }

    /// Waits for the currently tracked discovery task and its state publication.
    func waitForRefresh() async { await task?.value }
}
