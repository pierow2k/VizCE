import Foundation

@MainActor
struct RecognitionDelivery {
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
