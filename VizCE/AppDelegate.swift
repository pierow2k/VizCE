import AlinFoundation
import KeyboardShortcuts
import SwiftUI

/// Application lifecycle hooks that register shortcuts and wait for history before quitting.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowController = WindowManager.shared
    /// Whether the user has explicitly allowed termination after a history save failure.
    private var quitWithoutSaving = false

    /// Defers termination until history finishes saving and offers retry or discard actions on
    /// failure.
    ///
    /// Returns immediately only after the user has chosen to quit without saving.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !quitWithoutSaving else { return .terminateNow }
        Task { @MainActor in
            do {
                try await HistoryState.shared.flush()
                sender.reply(toApplicationShouldTerminate: true)
            } catch {
                sender.reply(toApplicationShouldTerminate: false)
                NSApp.activate()
                let alert = NSAlert()
                alert.messageText = String(localized: "History could not be saved")
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: String(localized: "Retry"))
                alert.addButton(withTitle: String(localized: "Cancel"))
                alert.addButton(withTitle: String(localized: "Quit Without Saving"))
                switch alert.runModal() {
                case .alertFirstButtonReturn:
                    HistoryState.shared.repository.retry()
                    sender.terminate(nil)

                case .alertThirdButtonReturn:
                    self.quitWithoutSaving = true
                    sender.terminate(nil)

                default:
                    break
                }
            }
        }
        return .terminateLater
    }

    /// Registers global shortcut actions and prepares application support storage in release
    /// builds.
    func applicationDidFinishLaunching(_: Notification) {
        KeyboardShortcuts.onKeyUp(for: .captureContent) {
            CaptureService.shared.captureContent()
        }

        KeyboardShortcuts.onKeyUp(for: .captureWebcam) {
            MenuPresentationController.shared.dismiss()
            openWebcamCapture()
        }

        KeyboardShortcuts.onKeyUp(for: .eyedropper) {
            processColor()
        }

        KeyboardShortcuts.onKeyUp(for: .history) {
            MenuPresentationController.shared.dismiss()
            self.windowController.open(
                id: "history",
                with: HistoryView(),
                width: 500,
                height: 600,
                material: .sidebar
            )
        }

        KeyboardShortcuts.onKeyUp(for: .clear) {
            clearCaptureHistoryAndClipboard()
        }

        #if !DEBUG
            ensureApplicationSupportFolderExists()
        #endif
    }
}
