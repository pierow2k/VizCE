import Foundation
import Vision

/// An actor that shares in-flight language discovery and caches successful results by
/// configuration.
actor RecognitionLanguageCatalog {
    static let shared = RecognitionLanguageCatalog()
    /// An injectable asynchronous query for language codes supported by one request configuration.
    typealias Discover = @Sendable (RecognitionConfiguration) async throws -> [String]

    private let discover: Discover
    /// Shared discovery tasks, retained after success and removed after failure so requests can
    /// retry.
    private var requests: [RecognitionConfiguration: Task<[String], Error>] = [:]

    /// Creates a catalog with an injectable language query, using Vision discovery by default.
    init(
        discover: @escaping Discover = { configuration in
            try await RecognitionLanguageCatalog.discoverSupportedCodes(configuration)
        }
    ) {
        self.discover = discover
    }

    /// Returns supported language codes, sharing an existing discovery task for the configuration.
    ///
    /// Successful tasks remain cached; failures remove the cached task and propagate the discovery
    /// error.
    func codes(for configuration: RecognitionConfiguration) async throws -> [String] {
        if let task = requests[configuration] { return try await task.value }
        let discover = discover
        let task = Task { try await discover(configuration) }
        requests[configuration] = task
        do { return try await task.value } catch {
            requests[configuration] = nil
            throw error
        }
    }

    /// Resolves a stored selection to a supported code or automatic language handling.
    ///
    /// - Parameters:
    ///   - selected: A Vision language code, `"All"`, or `nil`.
    ///   - configuration: The request quality and revision used to check availability.
    /// - Returns: The selected code if supported; `nil` for automatic handling or an unavailable
    ///   code.
    /// - Throws: The discovery error when a specific selection cannot be checked.
    func effectiveCode(
        _ selected: String?,
        for configuration: RecognitionConfiguration
    ) async throws -> String? {
        guard let selected, selected != "All" else { return nil }
        return try await codes(for: configuration).contains(selected) ? selected : nil
    }

    /// Queries Vision’s supported languages on a private queue for the requested quality and
    /// revision.
    ///
    /// - Throws: The Vision request’s language discovery error.
    nonisolated static func discoverSupportedCodes(
        _ configuration: RecognitionConfiguration
    ) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "VizCE.recognition.languages", qos: .userInitiated)
                .async {
                    do {
                        let request = VNRecognizeTextRequest()
                        request.recognitionLevel = configuration.fast ? .fast : .accurate
                        request.revision = configuration.revision
                        continuation.resume(returning: try request.supportedRecognitionLanguages())
                    } catch { continuation.resume(throwing: error) }
                }
        }
    }
}
