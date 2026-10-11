import AlinFoundation
import Foundation
import SwiftUI
import Vision

/// Main-actor orchestration of recognition, clipboard delivery, history, and optional shell processing.
@MainActor
struct TextRecognition {
    var recognizedContent = RecognizedContent.shared
    var image: NSImage
    var historyState: HistoryState
    /// The main-actor completion called after delivery, including empty, failed, or invalidated captures.
    var didFinishRecognition: @MainActor (RecognitionOutcome) -> Void

    /// Recognizes an image and shows a preview when delivery produces content.
    ///
    /// - Parameters:
    ///   - image: The captured image to encode and recognize.
    ///   - operationID: An existing capture token, or `nil` to begin a new capture generation.
    static func recognizeAndPreview(_ image: NSImage, operationID: UInt64? = nil) {
        Self(image: image, historyState: .shared) { outcome in
            if case .content = outcome {
                PreviewWindowController.shared.show(PreviewContentView())
            }
        }
        .recognizeContent(operationID: operationID)
    }

    /// Snapshots capture preferences, resolves language availability, and schedules recognition.
    ///
    /// - Parameter operationID: An existing capture token, or `nil` to allocate a new generation.
    func recognizeContent(operationID: UInt64? = nil) {
        let preferences = UserDefaults.standard
        let state = AppState.shared
        let options = RecognitionOptions(
            fast: state.selectedQuality == .fast,
            languageCode: state.selectedLanguageCode == "All" ? nil : state.selectedLanguageCode,
            keepLineBreaks: preferences.object(forKey: "keepLineBreaks") as? Bool ?? true,
            append: preferences.bool(forKey: "appendRecognizedText"),
            processing: preferences.bool(forKey: "processing"),
            commandTemplate: preferences.string(forKey: "postcommands") ?? "say [ocr];"
        )
        let token = operationID ?? state.beginCapture()
        let clearToken = state.clearGeneration
        guard let imageData = image.tiffRepresentation else {
            finish(.failure(.imageConversion), options: options, token: token, clearToken: clearToken)
            return
        }
        Task { @MainActor in
            do {
                let configuration = RecognitionConfiguration(fast: options.fast)
                let code = try await RecognitionLanguageCatalog.shared.effectiveCode(
                    options.languageCode,
                    for: configuration
                )
                let resolved = RecognitionOptions(
                    fast: options.fast,
                    languageCode: code,
                    keepLineBreaks: options.keepLineBreaks,
                    append: options.append,
                    processing: options.processing,
                    commandTemplate: options.commandTemplate
                )
                let outcome = await RecognitionWorker().outcome(imageData: imageData, options: resolved)
                finish(outcome, options: options, token: token, clearToken: clearToken)
            } catch {
                finish(
                    .failure(.recognition(error.localizedDescription)),
                    options: options,
                    token: token,
                    clearToken: clearToken
                )
            }
        }
    }

    /// Applies clear-generation and current-capture checks before delivering a recognition outcome.
    private func finish(_ outcome: RecognitionOutcome, options: RecognitionOptions, token: UInt64, clearToken: UInt64) {
        let state = AppState.shared
        RecognitionDelivery.finish(
            outcome,
            valid: state.clearGeneration == clearToken,
            current: state.captureIdentity.isCurrent(token),
            publish: { apply(text: $0, options: options, token: token) },
            notice: { CaptureNoticePresenter.shared.show($0) },
            completion: didFinishRecognition
        )
    }

    /// Publishes text to the clipboard and history, then optionally starts shell processing.
    ///
    /// Only the current capture may publish processing output; captured text is snapshotted before the task starts.
    private func apply(text: String, options: RecognitionOptions, token: UInt64) {
        let item = TextItem(text: text)
        if options.append { recognizedContent.items.append(item) } else { recognizedContent.items = [item] }
        copyTextItemsToClipboard(textItems: recognizedContent.items)
        playCaptureSound()
        historyState.append(.text(item))
        guard options.processing else { return }
        let contentSnapshot = recognizedContent.items.map(\.text).joined(separator: "\n")
        let state = AppState.shared
        if state.captureIdentity.isCurrent(token) { state.cmdOutput = "Running post-processing commands.." }
        Task { @MainActor in
            let output: String
            do {
                output = try await PostProcessingRunner()
                    .run(template: options.commandTemplate, content: contentSnapshot)
            } catch { output = "Post-processing failed: \(error.localizedDescription)" }
            guard state.captureIdentity.isCurrent(token) else { return }
            state.cmdOutput = output
        }
    }
}
