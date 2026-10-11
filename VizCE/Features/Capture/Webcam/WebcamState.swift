import Foundation

/// Camera lifecycle states used to select preview, still-image, and recovery controls.
enum WebcamState: Sendable, Equatable {
    case authorizing, captured, capturing
    /// A camera setup or still-capture failure carrying a localized recovery message.
    case failed(String)
    case idle, permissionDenied, previewing, starting

    var isStarting: Bool { self == .authorizing || self == .starting }
}
