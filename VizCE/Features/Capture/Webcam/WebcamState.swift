import Foundation

/// Camera lifecycle states used to select preview, still-image, and recovery controls.
enum WebcamState: Sendable, Equatable {
    case idle, authorizing, starting, previewing, capturing, captured, permissionDenied
    /// A camera setup or still-capture failure carrying a localized recovery message.
    case failed(String)

    var isStarting: Bool { self == .authorizing || self == .starting }
}
