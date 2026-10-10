import Foundation

enum ScreenCaptureOutcome: Sendable, Equatable {
    case image(Data)
    case cancelled
    case failure(CaptureFailure)
}
