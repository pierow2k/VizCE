import Foundation
import Vision

/// Shares in-flight discovery and caches successful results by request configuration.
actor RecognitionLanguageCatalog {
    static let shared = RecognitionLanguageCatalog()
    typealias Discover = @Sendable (RecognitionConfiguration) async throws -> [String]
    private let discover: Discover
    private var requests: [RecognitionConfiguration: Task<[String], Error>] = [:]

    init(discover: @escaping Discover = { configuration in
        try await RecognitionLanguageCatalog.discoverSupportedCodes(configuration)
    }) {
        self.discover = discover
    }

    func codes(for configuration: RecognitionConfiguration) async throws -> [String] {
        if let task = requests[configuration] { return try await task.value }
        let discover = discover
        let task = Task { try await discover(configuration) }
        requests[configuration] = task
        do { return try await task.value }
        catch { requests[configuration] = nil; throw error }
    }

    func effectiveCode(_ selected: String?, for configuration: RecognitionConfiguration) async throws -> String? {
        guard let selected, selected != "All" else { return nil }
        return try await codes(for: configuration).contains(selected) ? selected : nil
    }

    nonisolated static func discoverSupportedCodes(_ configuration: RecognitionConfiguration) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "Viz.recognition.languages", qos: .userInitiated).async {
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
