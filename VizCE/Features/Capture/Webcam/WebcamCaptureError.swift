import Foundation

/// Localized camera setup and capture failures, including superseded operation identifiers.
enum WebcamCaptureError: LocalizedError, Equatable, Sendable {
    case noDevice, unsupportedInput, unsupportedOutput, noFrame, conversionFailed, staleOperation, startFailed

    var errorDescription: String? {
        switch self {
        case .noDevice: return String(localized: "The selected camera is unavailable.")
        case .unsupportedInput: return String(localized: "The camera input could not be added.")
        case .unsupportedOutput: return String(localized: "The camera output could not be added.")
        case .noFrame: return String(localized: "No camera frame is available yet. Try Capture again.")
        case .conversionFailed: return String(localized: "The captured camera frame could not be converted to an image.")
        case .staleOperation: return String(localized: "The camera operation was superseded.")
        case .startFailed: return String(localized: "The camera session could not start.")
        }
    }
}
