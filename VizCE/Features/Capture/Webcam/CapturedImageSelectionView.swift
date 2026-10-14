import SwiftUI

/// A centered aspect-fill still image with a viewport-clamped drag selection.
struct CapturedImageSelectionView: View {
    let image: NSImage
    /// The available image viewport dimensions in points, used for aspect-fill display and drag
    /// clamping.
    let size: CGSize
    let isSnipping: Bool
    @Binding var selection: ImageSelectionState

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .accessibilityLabel("Captured image")
            Rectangle()
                .stroke(.blue, lineWidth: 2)
                .background(.blue.opacity(0.1))
                .frame(width: selection.rect.width, height: selection.rect.height)
                .position(x: selection.rect.midX, y: selection.rect.midY)
                .opacity(isSnipping && selection.rect != .zero ? 1 : 0)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onAppear { selection.updateViewport(size) }
        .onChange(of: size) { selection.updateViewport(size) }
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    guard isSnipping else { return }
                    selection.drag(start: value.startLocation, current: value.location)
                }
                .onEnded { _ in selection.endDrag() }
        )
        .onHover { inside in
            if inside, isSnipping { NSCursor.crosshair.set() } else { NSCursor.arrow.set() }
        }
    }
}
