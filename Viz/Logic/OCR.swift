import SwiftUI
import Vision
import Foundation
import AlinFoundation

@MainActor
struct TextRecognition {
    var recognizedContent = RecognizedContent.shared
    var image: NSImage
    var historyState: HistoryState
    var didFinishRecognition: @MainActor (RecognitionOutcome) -> Void

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
                let code = try await RecognitionLanguageCatalog.shared.effectiveCode(options.languageCode, for: configuration)
                let resolved = RecognitionOptions(fast: options.fast, languageCode: code, keepLineBreaks: options.keepLineBreaks,
                                                  append: options.append, processing: options.processing, commandTemplate: options.commandTemplate)
                let outcome = await RecognitionWorker().outcome(imageData: imageData, options: resolved)
                finish(outcome, options: options, token: token, clearToken: clearToken)
            } catch {
                finish(.failure(.recognition(error.localizedDescription)), options: options, token: token, clearToken: clearToken)
            }
        }
    }

    private func finish(_ outcome: RecognitionOutcome, options: RecognitionOptions, token: UInt64, clearToken: UInt64) {
        let state = AppState.shared
        RecognitionDelivery.finish(outcome, valid: state.clearGeneration == clearToken,
                                   current: state.captureIdentity.isCurrent(token),
                                   publish: { apply(text: $0, options: options, token: token) },
                                   notice: { CaptureNoticePresenter.shared.show($0) }, completion: didFinishRecognition)
    }

    private func apply(text: String, options: RecognitionOptions, token: UInt64) {
        let item = TextItem(text: text)
        if options.append { recognizedContent.items.append(item) }
        else { recognizedContent.items = [item] }
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
    private let worker = ScreenCaptureWorker()
    private var task: Task<Void, Never>?
    let recognizedContent = RecognizedContent.shared
    let pasteboard = NSPasteboard.general

    func cancelCapture() { task?.cancel() }

    func captureContent() {
        cancelCapture()
        let state = AppState.shared
        let token = state.beginCapture()
        CaptureNoticePresenter.shared.close()
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            CaptureNoticePresenter.shared.show(.failure(.screenPermission))
            return
        }
        task = Task {
            let outcome = await worker.capture()
            guard !Task.isCancelled, state.captureIdentity.isCurrent(token) else { return }
            switch outcome {
            case .image(let data):
                guard let image = NSImage(data: data) else {
                    CaptureNoticePresenter.shared.show(.failure(.imageConversion))
                    return
                }
                TextRecognition(recognizedContent: recognizedContent, image: image, historyState: HistoryState.shared) { result in
                    if case .content = result { showPreviewWindow(contentView: PreviewContentView()) }
                }.recognizeContent(operationID: token)
            case .failure(let error): CaptureNoticePresenter.shared.show(.failure(error))
            case .cancelled: break
            }
        }
    }
}
