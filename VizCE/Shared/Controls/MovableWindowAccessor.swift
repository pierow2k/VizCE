import SwiftUI

/// An AppKit bridge that requests dragging the containing window by its background.
struct MovableWindowAccessor: NSViewRepresentable {
    /// Creates a bridge view and attempts to enable background dragging on the next main-queue
    /// turn.
    func makeNSView(context _: Context) -> NSView {
        let nsView = NSView()

        DispatchQueue.main.async {
            if let window = nsView.window {
                // Defer window lookup so the bridge can attach to its containing window.
                window.isMovableByWindowBackground = true
            }
        }

        return nsView
    }

    func updateNSView(_: NSView, context _: Context) {
        // Background dragging is configured once when the bridge attaches to its window.
    }
}

extension View {
    /// Requests background dragging for the containing window through an AppKit bridge.
    func movableByWindowBackground() -> some View {
        self.background { MovableWindowAccessor() }
    }
}
