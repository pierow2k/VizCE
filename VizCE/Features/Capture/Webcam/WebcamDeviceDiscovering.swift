import Foundation

/// An asynchronous boundary for camera choices and the preferred default.
protocol WebcamDeviceDiscovering: Sendable {
    /// Discovers camera choices and their preferred default without returning mutable capture
    /// devices.
    func snapshot() async -> WebcamDevices
}
