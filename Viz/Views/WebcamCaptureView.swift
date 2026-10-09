//
//  WebcamCaptureView.swift
//  Viz
//
//  Created by Alin Lupascu on 8/29/25.
//

@preconcurrency import AVFoundation
import AlinFoundation
import SwiftUI
import Combine

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
        ZStack {
            // Full window content
            if let capturedImage = captureManager.capturedImage {
                if isSnipping {
                    GeometryReader { geometry in
                        ZStack {
                            Image(nsImage: capturedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                                .clipped()

                            // Selection overlay
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .background(Color.blue.opacity(0.1))
                                .frame(width: selection.rect.width, height: selection.rect.height)
                                .position(x: selection.rect.midX, y: selection.rect.midY)
                                .opacity(selection.rect != .zero ? 1 : 0)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .onAppear { selection.updateViewport(geometry.size) }
                        .onChange(of: geometry.size) { selection.updateViewport(geometry.size) }
                        .gesture(
                            DragGesture(coordinateSpace: .local)
                                .onChanged { value in
                                    selection.drag(start: value.startLocation, current: value.location)
                                }
                                .onEnded { _ in selection.endDrag() }
                        )
                    }
                    .background(Color.black)
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.crosshair.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                } else {
                    Image(nsImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .background(Color.black)
                }
            } else if let previewLayer = captureManager.previewLayer,
                      captureManager.state == .previewing || captureManager.state == .capturing {
                ZStack(alignment: .bottom) {
                    CameraPreviewView(previewLayer: previewLayer)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Button {
                        captureManager.capturePhoto()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                            Text("Capture")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(!captureManager.isPreviewActive)
                    .padding(.bottom, 20)
                }
            } else {
                WebcamRecoveryView(state: captureManager.state, devices: webcamManager.availableDevices,
                                   retry: {
                                       webcamManager.refresh()
                                       captureManager.restart(deviceID: selectedWebcamID)
                                   }, refresh: { webcamManager.refresh() }, choose: { selectedWebcamID = $0 })
            }

            // Bottom toolbar overlay
            if captureManager.capturedImage != nil {
                VStack {
                    Spacer()
                    HStack {
                        if isSnipping {
                            Spacer()

                            HStack(spacing: 15) {
                                Button {
                                    extractFromSelection()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.text.viewfinder")
                                            .font(.system(size: 14))
                                        Text("Extract")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                                .disabled(selectionCropRect == nil)

                                Button {
                                    selection.clear()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14))
                                        Text("Clear")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                                .disabled(selection.rect == .zero)

                                Button {
                                    isSnipping = false
                                    selection.clear()
                                    captureManager.restart(deviceID: selectedWebcamID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.backward")
                                            .font(.system(size: 14))
                                        Text("Back")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()
                        } else {
                            Spacer()

                            HStack(spacing: 15) {
                                Button {
                                    // Auto process entire image - stay on current screen
                                    TextRecognition(
                                        recognizedContent: RecognizedContent.shared,
                                        image: captureManager.capturedImage!,
                                        historyState: HistoryState.shared
                                    ) { outcome in
                                        if case .content = outcome { showPreviewWindow(contentView: PreviewContentView()) }
                                    }.recognizeContent()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 14))
                                        Text("Auto Extract")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    selection.clear()
                                    isSnipping = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "crop")
                                            .font(.system(size: 14))
                                        Text("Manual Extract")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    captureManager.restart(deviceID: selectedWebcamID)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.backward")
                                            .font(.system(size: 14))
                                        Text("Back")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }

            // Camera picker overlay
            if captureManager.capturedImage == nil {
                VStack {
                    HStack {
                        Spacer()

                        if !webcamManager.availableDevices.isEmpty {
                            Menu {
                                ForEach(webcamManager.availableDevices) { device in
                                    Button(device.name) {
                                        let newID = device.id
                                        if newID != selectedWebcamID {
                                            selectedWebcamID = newID
                                        }
                                    }
                                }
                            } label: {
                                Text(selectedWebcam?.name ?? "Select Camera")
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            .fixedSize()
                            .padding(6)
                            .padding(.horizontal, 2)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()

                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            captureManager.start(deviceID: selectedWebcamID)
        }
        .onDisappear { captureManager.stop() }
        .onChange(of: captureManager.capturedImage) { selection.clear() }
        .onChange(of: selectedWebcamID) {
            captureManager.start(deviceID: selectedWebcamID)
        }

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
              let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return ImageCropTransform.map(selection: selection.rect, viewport: selection.viewport,
                                      pixels: CGSize(width: pixels.width, height: pixels.height))
    }

    private func cropImage(image: NSImage, rect: CGRect) -> NSImage? {
        guard let pixels = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let crop = ImageCropTransform.map(selection: rect, viewport: selection.viewport,
                                                pixels: CGSize(width: pixels.width, height: pixels.height)),
              let cropped = pixels.cropping(to: crop) else { return nil }
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
