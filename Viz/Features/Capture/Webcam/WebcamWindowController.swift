import AppKit
import SwiftUI

@MainActor
final class WebcamWindowController: NSObject, NSWindowDelegate {
    static let shared = WebcamWindowController()
    private var window: NSWindow?
    private var coordinator: WebcamCaptureCoordinator?

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
            self.resize(window, for: image)
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === window else { return }
        coordinator?.stop()
        coordinator?.onCapture = nil
        closing.delegate = nil
        coordinator = nil
        window = nil
    }

    private func resize(_ window: NSWindow, for image: NSImage) {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return }
        let ratio = size.width / size.height
        let width: CGFloat
        let height: CGFloat
        if ratio > 1 {
            width = min(1200, size.width * 0.5)
            height = width / ratio
        } else {
            height = min(900, size.height * 0.5)
            width = height * ratio
        }
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
