import AppKit
import SwiftUI

/// Main-actor ownership of a reusable camera window and its capture coordinator.
@MainActor
final class WebcamWindowController: NSObject, NSWindowDelegate {
    static let shared = WebcamWindowController()
    private var window: NSWindow?
    private var coordinator: WebcamCaptureCoordinator?

    /// Brings forward the existing camera window or creates one with a fresh capture coordinator.
    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let coordinator = WebcamCaptureCoordinator()
        let window = NSWindow(contentViewController: NSHostingController(rootView: WebcamCaptureView(captureManager: coordinator)))
        window.setContentSize(NSSize(width: 650, height: 450))
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.level = .normal
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 320, height: 240)
        window.delegate = self
        window.center()
        self.coordinator = coordinator
        self.window = window
        coordinator.onCapture = { [weak self, weak coordinator] image in
            guard let self, self.coordinator === coordinator, let window = self.window else { return }
            resize(window, for: image)
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Stops camera work and releases state only when the closing window is the owned capture window.
    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === window else { return }
        coordinator?.stop()
        coordinator?.onCapture = nil
        closing.delegate = nil
        coordinator = nil
        window = nil
    }

    /// Fits the window to half the captured image dimensions, subject to orientation-specific size caps.
    ///
    /// Adds space for controls and animates unless Reduce Motion is enabled.
    private func resize(_ window: NSWindow, for image: NSImage) {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return }
        let ratio = size.width / size.height
        let width: CGFloat
        let height: CGFloat
        if ratio > 1 {
            width = min(1_200, size.width * 0.5)
            height = width / ratio
        } else {
            height = min(900, size.height * 0.5)
            width = height * ratio
        }
        // Reserve 80 points below the scaled image for the capture and extraction controls.
        let newSize = NSSize(width: width, height: height + 80)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            window.setContentSize(newSize)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().setContentSize(newSize)
        }
    }
}
