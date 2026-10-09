import AppKit
import SwiftUI

@MainActor
final class PreviewWindowController {
    static let shared = PreviewWindowController()
    private var window: NSWindow?
    private let expiry = PreviewExpiry()

    func close() {
        expiry.cancel()
        window?.orderOut(nil)
        window = nil
    }

    func show<Content: View>(_ content: Content) {
        @AppStorage("previewSeconds") var seconds: Double = 5.0
        @AppStorage("processing") var processing: Bool = false
        @AppStorage("showPreview") var showPreview: Bool = true
        @AppStorage("viewWidth") var width: Double = 300.0
        @AppStorage("viewHeight") var viewHeight: Double = 200.0
        guard showPreview else { return }
        close()
        let height = (processing && content is PreviewContentView) ? viewHeight + 100 : viewHeight
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        let presentation = NSWindow(contentRect: hostingView.frame, styleMask: .borderless, backing: .buffered, defer: false)
        presentation.contentView = hostingView
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 10
        hostingView.layer?.masksToBounds = true
        presentation.level = .floating
        presentation.isOpaque = false
        presentation.backgroundColor = .clear
        if let screen = NSScreen.main {
            presentation.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - width - 30,
                                               y: screen.visibleFrame.maxY - height - 30))
        }
        window = presentation
        presentation.orderFront(nil)
        expiry.schedule(after: .seconds(seconds)) { [weak self, weak presentation] in
            guard let self, let presentation, self.window === presentation else { return }
            self.close()
        }
    }
}
