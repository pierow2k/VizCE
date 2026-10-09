import Foundation

enum WebcamCaptureError: LocalizedError, Equatable {
    case noDevice, unsupportedInput, unsupportedOutput, noFrame, conversionFailed, staleOperation, startFailed

    var errorDescription: String? {
        switch self {
        case .noDevice: return "The selected camera is unavailable."
        case .unsupportedInput: return "The camera input could not be added."
        case .unsupportedOutput: return "The camera output could not be added."
        case .noFrame: return "No camera frame is available yet. Try Capture again."
        case .conversionFailed: return "The captured camera frame could not be converted to an image."
        case .staleOperation: return "The camera operation was superseded."
        case .startFailed: return "The camera session could not start."
        }
    }
}
