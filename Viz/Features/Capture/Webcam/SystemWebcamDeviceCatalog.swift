@preconcurrency import AVFoundation

actor SystemWebcamDeviceCatalog: WebcamDeviceDiscovering {
    static let shared = SystemWebcamDeviceCatalog()

    func snapshot() -> WebcamDevices {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external], mediaType: .video, position: .unspecified)
        let devices = discovery.devices.map { WebcamDevice(id: $0.uniqueID, name: $0.localizedName) }
        let preferred = discovery.devices.first { $0.deviceType == .builtInWideAngleCamera }?.uniqueID
        return WebcamDevices(devices: devices, defaultID: preferred ?? devices.first?.id)
    }
}
