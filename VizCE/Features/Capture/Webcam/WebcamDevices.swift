import Foundation

/// A camera discovery snapshot with an optional preferred device identifier.
struct WebcamDevices: Sendable {
    let devices: [WebcamDevice]
    /// The preferred camera identifier, or `nil` when discovery finds no available default.
    let defaultID: String?
    var defaultDevice: WebcamDevice? { devices.first { $0.id == defaultID } }
}
