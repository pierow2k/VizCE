import Vision

/// The recognition quality and Vision request revision used to key language discovery.
struct RecognitionConfiguration: Hashable, Sendable {
    /// Whether language discovery uses the fast Vision recognition level instead of accurate.
    let fast: Bool
    /// The Vision text request revision used when discovering supported languages.
    let revision: Int

    /// Creates a language discovery key for a recognition level and request revision.
    ///
    /// - Parameters:
    ///   - fast: Whether to query the fast recognition level rather than accurate.
    ///   - revision: The Vision request revision, defaulting to the framework’s current default.
    init(fast: Bool, revision: Int = VNRecognizeTextRequest.defaultRevision) {
        self.fast = fast
        self.revision = revision
    }
}
