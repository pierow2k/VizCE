import Foundation

/// Coordinate conversion from a top-left viewport selection to a centered aspect-fill image crop.
enum ImageCropTransform {
    /// Maps a visible selection to an outward-rounded pixel rectangle within the source image.
    ///
    /// - Parameters:
    ///   - selection: The selection rectangle in top-left viewport points; reversed dimensions are standardized.
    ///   - viewport: Finite, positive display dimensions in points.
    ///   - pixels: Finite, positive source image dimensions in pixels.
    /// - Returns: An integral crop including the centered aspect-fill offsets, or `nil` for invalid or empty input.
    static func map(selection: CGRect, viewport: CGSize, pixels: CGSize) -> CGRect? {
        guard valid(viewport), valid(pixels),
            [selection.origin.x, selection.origin.y, selection.width, selection.height].allSatisfy(\.isFinite)
        else { return nil }
        let visible = selection.standardized.intersection(CGRect(origin: .zero, size: viewport))
        guard !visible.isNull, !visible.isEmpty else { return nil }
        // Undo aspect-fill scaling, then restore the source pixels clipped from each centered edge.
        let inverseScale = min(pixels.width / viewport.width, pixels.height / viewport.height)
        let offsetX = (pixels.width - viewport.width * inverseScale) / 2
        let offsetY = (pixels.height - viewport.height * inverseScale) / 2
        let minX = visible.minX * inverseScale + offsetX
        let minY = visible.minY * inverseScale + offsetY
        let maxX = visible.maxX * inverseScale + offsetX
        let maxY = visible.maxY * inverseScale + offsetY
        guard inverseScale.isFinite, inverseScale > 0,
            [minX, minY, maxX, maxY].allSatisfy(\.isFinite)
        else { return nil }
        let bounds = CGRect(origin: .zero, size: pixels)
        let mapped = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).intersection(bounds)
        guard !mapped.isNull, !mapped.isEmpty else { return nil }
        // Round outward to retain every selected pixel, then clip again to the source bounds.
        let rounded = mapped.integral.intersection(bounds)
        return rounded.isNull || rounded.isEmpty ? nil : rounded
    }

    /// Clamps a finite drag point to the viewport edges.
    ///
    /// - Parameters:
    ///   - point: The drag location in viewport points.
    ///   - viewport: Finite, positive display dimensions.
    /// - Returns: The clamped location, or `nil` when the point or viewport is invalid.
    static func clamp(_ point: CGPoint, viewport: CGSize) -> CGPoint? {
        guard valid(viewport), point.x.isFinite, point.y.isFinite else { return nil }
        return CGPoint(
            x: min(max(point.x, 0), viewport.width),
            y: min(max(point.y, 0), viewport.height)
        )
    }

    /// Accepts only finite dimensions strictly greater than zero for coordinate conversion.
    private static func valid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0
    }
}
