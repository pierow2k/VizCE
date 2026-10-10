import SwiftUI

struct WebcamControlsView: View {
    let captured: Bool
    let snipping: Bool
    let canCapture: Bool
    let canExtract: Bool
    let capture: @MainActor () -> Void
    let autoExtract: @MainActor () -> Void
    let manualExtract: @MainActor () -> Void
    let extract: @MainActor () -> Void
    let cancel: @MainActor () -> Void
    let back: @MainActor () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { buttons }.fixedSize(horizontal: true, vertical: false)
            VStack(spacing: 6) { buttons }
        }
        .buttonStyle(.bordered)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder private var buttons: some View {
        if !captured {
            Button("Capture", systemImage: "camera.fill", action: capture).disabled(!canCapture)
        } else if snipping {
            Button("Extract", systemImage: "doc.text.viewfinder", action: extract).disabled(
                !canExtract)
            Button("Cancel selection", systemImage: "xmark", action: cancel)
            Button("Back", systemImage: "arrow.backward", action: back)
        } else {
            Button("Auto Extract", systemImage: "doc.text.viewfinder", action: autoExtract)
            Button("Manual Extract", systemImage: "crop", action: manualExtract)
            Button("Back", systemImage: "arrow.backward", action: back)
        }
    }
}
