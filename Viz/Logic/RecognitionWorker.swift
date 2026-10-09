import Foundation
import Vision

struct RecognitionWorker: Sendable {
    var operation: @Sendable (Data, RecognitionOptions) throws -> String = { data, options in
        try Self.perform(imageData: data, options: options)
    }

    func recognize(imageData: Data, options: RecognitionOptions) async throws -> String {
        let operation = operation
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: "Viz.recognition", qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try operation(imageData, options))
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    func outcome(imageData: Data, options: RecognitionOptions) async -> RecognitionOutcome {
        guard !Task.isCancelled else { return .cancelled }
        do {
            let text = try await recognize(imageData: imageData, options: options)
            guard !Task.isCancelled else { return .cancelled }
            return text.isEmpty ? .noContent : .content(text)
        } catch {
            return Task.isCancelled ? .cancelled : .failure(.recognition(error.localizedDescription))
        }
    }

    private static func perform(imageData: Data, options: RecognitionOptions) throws -> String {
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = options.fast ? .fast : .accurate
        textRequest.usesLanguageCorrection = true
        if let language = options.languageCode { textRequest.recognitionLanguages = [language] }
        let barcodeRequest = VNDetectBarcodesRequest()
        try VNImageRequestHandler(data: imageData, options: [:]).perform([textRequest, barcodeRequest])
        let lines = (textRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let barcodes = (barcodeRequest.results ?? []).map { $0.payloadStringValue ?? "Unknown value" }
        func joined(_ strings: [String]) -> String {
            if options.keepLineBreaks { return strings.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) }
            return strings.isEmpty ? "" : strings.joined(separator: " ") + " "
        }
        return [joined(lines), joined(barcodes)].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
