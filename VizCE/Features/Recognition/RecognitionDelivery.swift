import Foundation

/// Main-actor delivery rules for publishing captures and suppressing stale notices.
@MainActor
struct RecognitionDelivery {
    /// Publishes valid content, shows current notices, and calls completion once.
    ///
    /// Valid content from an older capture still publishes; only notices require a current capture.
    ///
    /// - Parameters:
    ///   - outcome: The worker result to deliver.
    ///   - valid: Whether no clear has invalidated this capture; `false` completes as canceled.
    ///   - current: Whether this capture is still the latest for notice presentation.
    ///   - publish: Receives recognized content when the capture is valid.
    ///   - notice: Receives empty results or failures only when the capture is current.
    ///   - completion: Receives the delivered outcome, or cancellation when invalidated.
    static func finish(_ outcome: RecognitionOutcome, valid: Bool, current: Bool,
                       publish: (String) -> Void, notice: (RecognitionOutcome) -> Void,
                       completion: (RecognitionOutcome) -> Void) {
        guard valid else { completion(.cancelled); return }
        switch outcome {
        case .content(let text): publish(text)

        case .noContent, .failure:
            if current { notice(outcome) }

        case .cancelled: break
        }
        completion(outcome)
    }
}
