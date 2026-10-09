import Foundation

struct ImageSelectionState {
    private(set) var viewport: CGSize = .zero
    private(set) var rect: CGRect = .zero
    private(set) var isDragging = false
    private var dragStart: CGPoint = .zero

    mutating func updateViewport(_ size: CGSize) {
        guard viewport != size else { return }
        viewport = size
        clear()
    }

    mutating func drag(start: CGPoint, current: CGPoint) {
        guard let start = ImageCropTransform.clamp(start, viewport: viewport),
              let current = ImageCropTransform.clamp(current, viewport: viewport) else {
            clear()
            return
        }
        if !isDragging { dragStart = start; isDragging = true }
        rect = CGRect(x: min(dragStart.x, current.x), y: min(dragStart.y, current.y),
                      width: abs(current.x - dragStart.x), height: abs(current.y - dragStart.y))
    }

    mutating func endDrag() { isDragging = false; dragStart = .zero }

    mutating func clear() { rect = .zero; isDragging = false; dragStart = .zero }
}
