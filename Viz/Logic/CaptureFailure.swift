import Foundation

enum CaptureFailure: Error, LocalizedError, Sendable, Equatable {
    case imageConversion
    case recognition(String)
    case screenPermission
    case screenCapture(String)

    var errorDescription: String? {
        switch self {
        case .imageConversion: String(localized: "The captured image could not be read. Try capturing again.")
        case .recognition(let message): String(localized: "Recognition failed: \(message)")
        case .screenPermission: String(localized: "Allow Viz to record the screen in System Settings, then try again.")
        case .screenCapture(let message): String(localized: "Screen capture failed: \(message)")
        }
    }
}
