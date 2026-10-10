import AppKit
import SwiftUI

/// A retained main-actor window for reporting failures or empty recognition results.
@MainActor
final class CaptureNoticePresenter {
    static let shared = CaptureNoticePresenter()
    private var window: NSWindow?

    /// Replaces the notice window for an empty result or failure and activates the application.
    ///
    /// Content and cancellation outcomes leave the current notice unchanged.
    func show(_ outcome: RecognitionOutcome) {
        let title: LocalizedStringResource
        let message: String
        switch outcome {
        case .noContent:
            title = "No content recognized"
            message = String(localized: "No text or barcode was found in the selection.")
        case .failure(let error):
            title = "Capture failed"
            message = error.localizedDescription
        default: return
        }
        close()
        let view = CaptureNoticeView(title: title, message: message, close: { [weak self] in self?.close() })
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = String(localized: title)
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 400, height: 180))
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// Closes and releases the currently retained notice window.
    func close() { window?.close(); window = nil }
}
