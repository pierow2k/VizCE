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
            // The parent insets already reduce this reader to the image's available space.
            let viewport = geometry.size
            ZStack {
                if let image = captureManager.capturedImage {
                    CapturedImageSelectionView(
                        image: image, size: viewport, isSnipping: isSnipping, selection: $selection)
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
        .frame(minWidth: 320, minHeight: 240)
        .onAppear { captureManager.start(deviceID: selectedWebcamID) }
        .onDisappear { captureManager.stop() }
        .onChange(of: captureManager.capturedImage) {
            selection.clear()
            if captureManager.capturedImage == nil { isSnipping = false }
        }
        .onChange(of: selectedWebcamID) { captureManager.start(deviceID: selectedWebcamID) }
    }

    private func restart() {
        selection.clear()
        isSnipping = false
        webcamManager.refresh()
        captureManager.restart(deviceID: selectedWebcamID)
    }

    private func extractWholeImage() {
        guard let image = captureManager.capturedImage else { return }
        TextRecognition.recognizeAndPreview(image)
    }

    private func extractFromSelection() {
        guard let image = captureManager.capturedImage, selection.rect != .zero else { return }

        // Crop the image based on selection
        if let croppedImage = cropImage(image: image, rect: selection.rect) {
            TextRecognition.recognizeAndPreview(croppedImage)

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
