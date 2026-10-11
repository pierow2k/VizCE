@preconcurrency import AVFoundation

/// An actor that discovers built-in and external cameras without exposing capture devices.
actor SystemWebcamDeviceCatalog: WebcamDeviceDiscovering {
    static let shared = SystemWebcamDeviceCatalog()

    /// Discovers cameras and prefers a built-in camera, falling back to the first available device.
    func snapshot() -> WebcamDevices {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discovery.devices.map { WebcamDevice(id: $0.uniqueID, name: $0.localizedName) }
        let preferred = discovery.devices.first { $0.deviceType == .builtInWideAngleCamera }?.uniqueID
        return WebcamDevices(devices: devices, defaultID: preferred ?? devices.first?.id)
    }
}
