import Vision

struct RecognitionConfiguration: Hashable, Sendable {
    let fast: Bool
    let revision: Int

    init(fast: Bool, revision: Int = VNRecognizeTextRequest.defaultRevision) {
        self.fast = fast
        self.revision = revision
    }
}
