import Foundation

/// User-facing failures from screen acquisition, image conversion, or recognition.
enum CaptureFailure: Error, LocalizedError, Sendable, Equatable {
    case imageConversion
    /// A recognition failure carrying details from the underlying error.
    case recognition(String)
    /// A screen subprocess failure carrying diagnostic or launch details.
    case screenCapture(String)
    case screenPermission

    var errorDescription: String? {
        switch self {
        case .imageConversion:
            String(localized: "The captured image could not be read. Try capturing again.")

        case .recognition(let message):
            String(localized: "Recognition failed: \(message)")

        case .screenPermission:
            String(localized: "Allow VizCE to record the screen in System Settings, then try again.")

        case .screenCapture(let message):
            String(localized: "Screen capture failed: \(message)")
        }
    }
}
