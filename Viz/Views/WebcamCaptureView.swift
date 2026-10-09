//
//  WebcamCaptureView.swift
//  Viz
//
//  Created by Alin Lupascu on 8/29/25.
//

@preconcurrency import AVFoundation
import AlinFoundation
import Combine
import SwiftUI

struct WebcamCaptureView: View {
    @ObservedObject var captureManager: WebcamCaptureCoordinator
    @StateObject private var webcamManager = WebcamManager()
    @AppStorage("selectedWebcamID") private var selectedWebcamID: String = ""
    @State private var isSnipping: Bool = false
    @State private var selection = ImageSelectionState()

    var selectedWebcam: WebcamDevice? {
        if selectedWebcamID.isEmpty {
            return webcamManager.defaultDevice
        }
        return webcamManager.availableDevices.first { $0.id == selectedWebcamID }
    }

    var body: some View {
        GeometryReader { geometry in
            // Insets identify the space reserved for title-bar and adaptive controls.
            let insets = geometry.safeAreaInsets
            let viewport = CGSize(
                width: max(0, geometry.size.width - insets.leading - insets.trailing),
                height: max(0, geometry.size.height - insets.top - insets.bottom))
            ZStack {
                if let image = captureManager.capturedImage {
                    imageViewport(image, size: viewport)
                } else if let preview = captureManager.previewLayer,
                    captureManager.state == .previewing || captureManager.state == .capturing
                {
                    CameraPreviewView(previewLayer: preview)
                } else {
                    WebcamRecoveryView(
                        state: captureManager.state, devices: webcamManager.availableDevices,
                        retry: restart, refresh: { webcamManager.refresh() },
                        choose: { selectedWebcamID = $0 })
                }
            }
            .frame(width: viewport.width, height: viewport.height)
            .offset(x: insets.leading, y: insets.top)
        }
        .background { Color.black.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if captureManager.capturedImage != nil || captureManager.previewLayer != nil {
                WebcamControlsView(
                    captured: captureManager.capturedImage != nil, snipping: isSnipping,
                    canCapture: captureManager.isPreviewActive,
                    canExtract: selectionCropRect != nil,
                    capture: { captureManager.capturePhoto() }, autoExtract: extractWholeImage,
                    manualExtract: {
                        selection.clear()
                        isSnipping = true
                    }, extract: extractFromSelection,
                    cancel: {
                        selection.clear()
                        isSnipping = false
                    }, back: restart)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if captureManager.capturedImage == nil, !webcamManager.availableDevices.isEmpty {
                WebcamCameraPicker(
                    devices: webcamManager.availableDevices, selection: selectedWebcam,
                    choose: { selectedWebcamID = $0 })
            }
        }
        .onAppear { captureManager.start(deviceID: selectedWebcamID) }
        .onDisappear { captureManager.stop() }
        .onChange(of: captureManager.capturedImage) {
            selection.clear()
            if captureManager.capturedImage == nil { isSnipping = false }
        }
        .onChange(of: selectedWebcamID) { captureManager.start(deviceID: selectedWebcamID) }
    }

    private func imageViewport(_ image: NSImage, size: CGSize) -> some View {
        ZStack {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height).clipped()
            Rectangle().stroke(.blue, lineWidth: 2).background(.blue.opacity(0.1))
                .frame(width: selection.rect.width, height: selection.rect.height)
                .position(x: selection.rect.midX, y: selection.rect.midY)
                .opacity(isSnipping && selection.rect != .zero ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onAppear { selection.updateViewport(size) }
        .onChange(of: size) { selection.updateViewport(size) }
        .gesture(
            DragGesture(coordinateSpace: .local).onChanged { value in
                guard isSnipping else { return }
                selection.drag(start: value.startLocation, current: value.location)
            }.onEnded { _ in selection.endDrag() }
        )
        .onHover { inside in
            if inside && isSnipping { NSCursor.crosshair.set() } else { NSCursor.arrow.set() }
        }
    }

    private func restart() {
        selection.clear()
        isSnipping = false
        webcamManager.refresh()
        captureManager.restart(deviceID: selectedWebcamID)
    }

    private func extractWholeImage() {
        guard let image = captureManager.capturedImage else { return }
        TextRecognition(
            recognizedContent: RecognizedContent.shared, image: image,
            historyState: HistoryState.shared
        ) { result in
            if case .content = result { showPreviewWindow(contentView: PreviewContentView()) }
        }.recognizeContent()
    }

    private func extractFromSelection() {
        guard let image = captureManager.capturedImage, selection.rect != .zero else { return }

        // Crop the image based on selection
        if let croppedImage = cropImage(image: image, rect: selection.rect) {
            TextRecognition(
                recognizedContent: RecognizedContent.shared, image: croppedImage,
                historyState: HistoryState.shared
            ) { outcome in
                if case .content = outcome { showPreviewWindow(contentView: PreviewContentView()) }
            }.recognizeContent()

            // Reset to captured image view
            isSnipping = false
            selection.clear()
        }
    }

    private var selectionCropRect: CGRect? {
        guard let image = captureManager.capturedImage,
            let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        return ImageCropTransform.map(
            selection: selection.rect, viewport: selection.viewport,
            pixels: CGSize(width: pixels.width, height: pixels.height))
    }

    private func cropImage(image: NSImage, rect: CGRect) -> NSImage? {
        guard let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
            let crop = ImageCropTransform.map(
                selection: rect, viewport: selection.viewport,
                pixels: CGSize(width: pixels.width, height: pixels.height)),
            let cropped = pixels.cropping(to: crop)
        else { return nil }
        return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    }

}

struct CameraPreviewView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer = previewLayer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer = previewLayer
        previewLayer.frame = nsView.bounds
    }
}

struct CapturedImageView: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 480, height: 360)
            .background(Color.black)
    }
}
