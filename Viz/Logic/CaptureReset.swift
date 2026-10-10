@MainActor
func clearCaptureHistoryAndClipboard(historyState: HistoryState? = nil) {
    AppState.shared.invalidateCaptures()
    CaptureService.shared.cancelCapture()
    CaptureNoticePresenter.shared.close()
    CaptureService.shared.recognizedContent.items.removeAll()
    CaptureService.shared.pasteboard.clearContents()
    (historyState ?? .shared).clear()
    PreviewWindowController.shared.close()
}
