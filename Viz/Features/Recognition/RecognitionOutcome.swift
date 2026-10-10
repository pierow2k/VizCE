import Foundation

enum RecognitionOutcome: Sendable, Equatable {
    case content(String)
    case noContent
    case cancelled
    case failure(CaptureFailure)
}
