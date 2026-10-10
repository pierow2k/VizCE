@preconcurrency import AVFoundation
import SwiftUI

/// An AppKit bridge that fits the live camera preview layer to its view bounds.
struct CameraPreviewView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    /// Creates a layer-backed view attached to the supplied camera preview layer.
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer = previewLayer
        view.wantsLayer = true
        return view
    }

    /// Reattaches the current preview layer and resizes it to the view bounds.
    ///
    /// - Parameters:
    ///   - nsView: The hosted camera view.
    ///   - context: The SwiftUI representable context.
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer = previewLayer
        previewLayer.frame = nsView.bounds
    }
}
