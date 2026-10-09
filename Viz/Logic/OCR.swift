import SwiftUI
import Vision
import Foundation
import AlinFoundation

@MainActor
struct TextRecognition {
    var recognizedContent = RecognizedContent.shared
    var image: NSImage
    var historyState: HistoryState
    var didFinishRecognition: @MainActor () -> Void

    func recognizeContent() {
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
        let token = state.beginCapture()
        let clearToken = state.clearGeneration
        guard let imageData = image.tiffRepresentation else {
            apply(text: "", options: options, token: token)
            return
        }
        Task { @MainActor in
            do {
                let configuration = RecognitionConfiguration(fast: options.fast)
                let code = try await RecognitionLanguageCatalog.shared.effectiveCode(options.languageCode, for: configuration)
                let resolved = RecognitionOptions(fast: options.fast, languageCode: code, keepLineBreaks: options.keepLineBreaks,
                                                  append: options.append, processing: options.processing, commandTemplate: options.commandTemplate)
                let text = try await RecognitionWorker().recognize(imageData: imageData, options: resolved)
                guard state.clearGeneration == clearToken else { return }
                apply(text: text, options: options, token: token)
            } catch {
                guard state.clearGeneration == clearToken else { return }
                apply(text: "", options: options, token: token)
                if state.captureIdentity.isCurrent(token) { state.cmdOutput = "Recognition failed: \(error.localizedDescription)" }
            }
        }
    }

    private func apply(text: String, options: RecognitionOptions, token: UInt64) {
        let failed = text.isEmpty
        let item = TextItem(text: failed ? "Unable to extract any content from selection" : text)
        if options.append { recognizedContent.items.append(item) }
        else { recognizedContent.items = [item] }
        didFinishRecognition()
        guard !failed else { return }
        copyTextItemsToClipboard(textItems: recognizedContent.items)
        playSound(for: .text(item))
        historyState.append(.text(item))
        guard options.processing else { return }
        let contentSnapshot = recognizedContent.items.map(\.text).joined(separator: "\n")
        let state = AppState.shared
        if state.captureIdentity.isCurrent(token) { state.cmdOutput = "Running post-processing commands.." }
        Task { @MainActor in
            let output: String
            do { output = try await PostProcessingRunner().run(template: options.commandTemplate, content: contentSnapshot) }
            catch { output = "Post-processing failed: \(error.localizedDescription)" }
            guard state.captureIdentity.isCurrent(token) else { return }
            state.cmdOutput = output
        }
    }
}

@MainActor
final class CaptureService {
    static let shared = CaptureService()
    let screenCaptureUtility = ScreenCaptureUtility()
    let recognizedContent = RecognizedContent.shared
    let pasteboard = NSPasteboard.general

    func captureContent() {
        let state = AppState.shared
        state.beginCapture()
        let clearToken = state.clearGeneration
        screenCaptureUtility.captureScreenSelectionToClipboard { image in
            guard state.clearGeneration == clearToken, let image else { return }
            TextRecognition(recognizedContent: self.recognizedContent, image: image, historyState: HistoryState.shared) {
                showPreviewWindow(contentView: PreviewContentView())
            }.recognizeContent()
        }
    }
}
