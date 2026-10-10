import Combine
import Foundation

@MainActor
final class WebcamManager: ObservableObject {
    @Published private(set) var availableDevices: [WebcamDevice] = []
    @Published private(set) var defaultDevice: WebcamDevice?
    private let provider: any WebcamDeviceDiscovering
    private var task: Task<Void, Never>?
    private var generation: UInt64 = 0

    init(provider: any WebcamDeviceDiscovering = SystemWebcamDeviceCatalog.shared) {
        self.provider = provider
        refresh()
    }

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

    func waitForRefresh() async { await task?.value }
}
