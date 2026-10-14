import Foundation

/// A drag selection in viewport points that is cleared when the viewport changes.
struct ImageSelectionState {
    /// The display dimensions in points used to clamp the current drag.
    private(set) var viewport: CGSize = .zero
    /// The normalized viewport selection in points; `.zero` represents a cleared or empty
    /// selection.
    private(set) var rect: CGRect = .zero
    private(set) var isDragging = false
    /// The clamped anchor retained until the current drag ends or is cleared.
    private var dragStart: CGPoint = .zero

    /// Updates viewport dimensions and clears any selection when they change.
    mutating func updateViewport(_ size: CGSize) {
        guard viewport != size else { return }
        viewport = size
        clear()
    }

    /// Updates the rectangle from a fixed drag anchor and clamps both points to the viewport.
    ///
    /// - Parameters:
    ///   - start: The gesture’s initial location, captured as the anchor when a drag begins.
    ///   - current: The latest gesture location used to form the selection.
    mutating func drag(start: CGPoint, current: CGPoint) {
        guard let start = ImageCropTransform.clamp(start, viewport: viewport),
            let current = ImageCropTransform.clamp(current, viewport: viewport)
        else {
            clear()
            return
        }
        if !isDragging {
            dragStart = start
            isDragging = true
        }
        rect = CGRect(
            x: min(dragStart.x, current.x),
            y: min(dragStart.y, current.y),
            width: abs(current.x - dragStart.x),
            height: abs(current.y - dragStart.y)
        )
    }

    /// Ends the drag and clears its anchor while retaining the selected rectangle.
    mutating func endDrag() {
        isDragging = false
        dragStart = .zero
    }

    /// Clears the selection rectangle and any active drag anchor.
    mutating func clear() {
        rect = .zero
        isDragging = false
        dragStart = .zero
    }
}
