//
//  WebcamCaptureView.swift
//  VizCE
//
//  Created by Alin Lupascu on 8/29/25.
//

import AlinFoundation
@preconcurrency import AVFoundation
import Combine
import SwiftUI

/// Live camera capture, recovery controls, and recognition of a whole still image or selection.
struct WebcamCaptureView: View {
    @ObservedObject var captureManager: WebcamCaptureCoordinator
    @StateObject private var webcamManager = WebcamManager()
    /// The saved camera identifier; an empty string requests the preferred default camera.
    @AppStorage("selectedWebcamID") private var selectedWebcamID: String = ""
    @State private var isSnipping: Bool = false
    @State private var selection = ImageSelectionState()

    /// The saved camera if still available, or the preferred default only when no identifier is saved.
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
                    captureManager.state == .previewing || captureManager.state == .capturing {
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
                    devices: webcamManager.availableDevices, selection: selectedWebcam) { selectedWebcamID = $0 }
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

    /// Clears selection mode, refreshes camera choices, and requests preview startup.
    private func restart() {
        selection.clear()
        isSnipping = false
        webcamManager.refresh()
        captureManager.restart(deviceID: selectedWebcamID)
    }

    /// Starts recognition and preview for the captured still image, if available.
    private func extractWholeImage() {
        guard let image = captureManager.capturedImage else { return }
        TextRecognition.recognizeAndPreview(image)
    }

    /// Recognizes a valid selected crop and returns to the still-image controls after a successful crop.
    private func extractFromSelection() {
        guard let image = captureManager.capturedImage, selection.rect != .zero else { return }

        if let croppedImage = cropImage(image: image, rect: selection.rect) {
            TextRecognition.recognizeAndPreview(croppedImage)

            isSnipping = false
            selection.clear()
        }
    }

    /// The valid pixel crop for the current viewport selection, or `nil` when extraction is unavailable.
    private var selectionCropRect: CGRect? {
        guard let image = captureManager.capturedImage,
            let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        return ImageCropTransform.map(
            selection: selection.rect, viewport: selection.viewport,
            pixels: CGSize(width: pixels.width, height: pixels.height))
    }

    /// Converts a viewport selection to a centered aspect-fill pixel crop and creates a still image.
    ///
    /// - Parameters:
    ///   - image: The source still image whose pixel dimensions define the crop bounds.
    ///   - rect: The selection in points within `selection.viewport`.
    /// - Returns: A cropped image, or `nil` for invalid coordinates or unavailable image pixels.
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
