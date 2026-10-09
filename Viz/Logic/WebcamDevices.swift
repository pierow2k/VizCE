import Foundation

struct WebcamDevices: Sendable {
    let devices: [WebcamDevice]
    let defaultID: String?
    var defaultDevice: WebcamDevice? { devices.first { $0.id == defaultID } }
}
