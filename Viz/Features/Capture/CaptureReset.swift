/// Invalidates earlier captures, cancels screen acquisition, and clears clipboard, text, and history.
///
/// Also closes notices and previews. The last sampled color remains in application state.
///
/// - Parameter historyState: The history to clear, or shared history when `nil`.
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
