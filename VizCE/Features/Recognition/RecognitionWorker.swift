import Foundation
import Vision

/// An asynchronous text and barcode recognizer that performs blocking work on a private queue.
struct RecognitionWorker: Sendable {
    /// The blocking recognition operation, injected by tests and run on a private queue.
    var operation: @Sendable (Data, RecognitionOptions) throws -> String = { data, options in
        try Self.perform(imageData: data, options: options)
    }

    /// Runs the blocking recognition operation on a private queue.
    ///
    /// - Parameters:
    ///   - imageData: Encoded image bytes accepted by the recognition operation.
    ///   - options: Capture-time preferences frozen before work starts.
    /// - Returns: The combined text and barcode result, which may be empty.
    /// - Throws: Errors from the recognition operation.
    func recognize(imageData: Data, options: RecognitionOptions) async throws -> String {
        let operation = operation
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "VizCE.recognition", qos: .userInitiated)
                .async {
                    do {
                        continuation.resume(returning: try operation(imageData, options))
                    } catch { continuation.resume(throwing: error) }
                }
        }
    }

    /// Converts recognition output and errors into typed outcomes, checking cancellation before and
    /// after work.
    ///
    /// - Parameters:
    ///   - imageData: Encoded image bytes to recognize.
    ///   - options: Capture-time preferences passed to the worker.
    /// - Returns: Cancellation takes precedence over a completed result or error.
    func outcome(imageData: Data, options: RecognitionOptions) async -> RecognitionOutcome {
        guard !Task.isCancelled else { return .cancelled }
        do {
            let text = try await recognize(imageData: imageData, options: options)
            guard !Task.isCancelled else { return .cancelled }
            return text.isEmpty ? .noContent : .content(text)
        } catch {
            return Task.isCancelled
                ? .cancelled : .failure(.recognition(error.localizedDescription))
        }
    }

    /// Recognizes text and barcodes, joining each group according to the line-break preference.
    private static func perform(imageData: Data, options: RecognitionOptions) throws -> String {
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = options.fast ? .fast : .accurate
        textRequest.usesLanguageCorrection = true
        if let language = options.languageCode { textRequest.recognitionLanguages = [language] }
        let barcodeRequest = VNDetectBarcodesRequest()
        try VNImageRequestHandler(data: imageData, options: [:]).perform([
            textRequest,
            barcodeRequest,
        ])
        let lines = (textRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let barcodes = (barcodeRequest.results ?? []).map { barcode in
            barcode.payloadStringValue ?? "Unknown value"
        }
        // Preserves line breaks with trimmed edges, or joins with spaces and a trailing space for a
        // nonempty group.
        func joined(_ strings: [String]) -> String {
            if options.keepLineBreaks {
                return strings.joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return strings.isEmpty ? "" : strings.joined(separator: " ") + " "
        }
        return [joined(lines), joined(barcodes)].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
