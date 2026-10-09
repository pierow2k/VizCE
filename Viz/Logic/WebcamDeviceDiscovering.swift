import Foundation

protocol WebcamDeviceDiscovering: Sendable {
    func snapshot() async -> WebcamDevices
}
