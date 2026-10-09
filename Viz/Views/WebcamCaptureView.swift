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
    @State private var selectionRect: CGRect = .zero
    @State private var isDragging: Bool = false
    @State private var dragStart: CGPoint = .zero
    @State private var viewSize: CGSize = .zero

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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()

                            // Selection overlay
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .background(Color.blue.opacity(0.1))
                                .frame(width: selectionRect.width, height: selectionRect.height)
                                .position(x: selectionRect.midX, y: selectionRect.midY)
                                .opacity(selectionRect != .zero ? 1 : 0)
                        }
                        .onAppear {
                            viewSize = geometry.size
                        }
                        .onChange(of: geometry.size) { newSize in
                            viewSize = newSize
                        }
                        .gesture(
                            DragGesture(coordinateSpace: .local)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragStart = value.startLocation
                                    }

                                    let currentLocation = value.location
                                    let minX = min(dragStart.x, currentLocation.x)
                                    let minY = min(dragStart.y, currentLocation.y)
                                    let width = abs(currentLocation.x - dragStart.x)
                                    let height = abs(currentLocation.y - dragStart.y)

                                    selectionRect = CGRect(
                                        x: minX, y: minY, width: width, height: height)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
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
            } else if let previewLayer = captureManager.previewLayer {
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
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        VStack(spacing: 15) {
                            if captureManager.permissionDenied {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.red)
                                Text("Camera access denied")
                                    .foregroundStyle(.red)
                                    .font(.headline)

                                Button {
                                    NSWorkspace.shared.open(
                                        URL(
                                            string:
                                                "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                                        )!)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gear")
                                            .font(.system(size: 14))
                                        Text("Open Settings")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                                Text(captureManager.isStarting ? "Starting Camera" : "Camera unavailable")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
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
                                .disabled(selectionRect == .zero)

                                Button {
                                    selectionRect = .zero
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
                                .disabled(selectionRect == .zero)

                                Button {
                                    isSnipping = false
                                    selectionRect = .zero
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
                                    ) {
                                        showPreviewWindow(contentView: PreviewContentView())
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

                        if webcamManager.availableDevices.count > 1 {
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
            if selectedWebcamID.isEmpty { selectedWebcamID = webcamManager.defaultDevice?.id ?? "" }
            captureManager.start(deviceID: selectedWebcamID)
        }
        .onDisappear { captureManager.stop() }
        .onChange(of: selectedWebcamID) {
            captureManager.start(deviceID: selectedWebcamID)
        }
        .alert("Camera capture failed", isPresented: Binding(
            get: { captureManager.errorMessage != nil },
            set: { if !$0 { captureManager.dismissError() } }
        )) {
            Button("OK") { captureManager.dismissError() }
        } message: {
            Text(captureManager.errorMessage ?? "")
        }
    }

    private func extractFromSelection() {
        guard let image = captureManager.capturedImage, selectionRect != .zero else { return }

        // Crop the image based on selection
        if let croppedImage = cropImage(image: image, rect: selectionRect) {
            TextRecognition(
                recognizedContent: RecognizedContent.shared, image: croppedImage,
                historyState: HistoryState.shared
            ) {
                showPreviewWindow(contentView: PreviewContentView())
            }.recognizeContent()

            // Reset to captured image view
            isSnipping = false
            selectionRect = .zero
        }
    }

    private func cropImage(image: NSImage, rect: CGRect) -> NSImage? {
        let imageSize = image.size

        // Convert selection rect to image coordinates using actual view size
        let cropRect = CGRect(
            x: rect.minX / viewSize.width * imageSize.width,
            y: rect.minY / viewSize.height * imageSize.height,
            width: rect.width / viewSize.width * imageSize.width,
            height: rect.height / viewSize.height * imageSize.height
        )

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }

        return NSImage(
            cgImage: croppedCGImage,
            size: NSSize(width: croppedCGImage.width, height: croppedCGImage.height))
    }
}

struct WebcamDevice: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class WebcamManager: ObservableObject {
    @Published var availableDevices: [WebcamDevice] = []
    @Published var defaultDevice: WebcamDevice?

    init() {
        loadAvailableDevices()
    }

    func loadAvailableDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )

        var devices: [WebcamDevice] = []
        var builtInDevice: WebcamDevice?

        for device in discoverySession.devices {
            let webcamDevice = WebcamDevice(id: device.uniqueID, name: device.localizedName)
            devices.append(webcamDevice)

            if device.deviceType == .builtInWideAngleCamera {
                builtInDevice = webcamDevice
            }
        }

        self.availableDevices = devices
        self.defaultDevice = builtInDevice ?? devices.first
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
