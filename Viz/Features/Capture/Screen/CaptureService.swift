import SwiftUI

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
                TextRecognition.recognizeAndPreview(image, operationID: token)
            case .failure(let error): CaptureNoticePresenter.shared.show(.failure(error))
            case .cancelled: break
            }
        }
    }
}
