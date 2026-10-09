import Foundation

/// Converts top-left viewport coordinates to pixels for a centered aspect-fill image.
enum ImageCropTransform {
    static func map(selection: CGRect, viewport: CGSize, pixels: CGSize) -> CGRect? {
        guard valid(viewport), valid(pixels),
              [selection.origin.x, selection.origin.y, selection.width, selection.height].allSatisfy(\.isFinite) else { return nil }
        let visible = selection.standardized.intersection(CGRect(origin: .zero, size: viewport))
        guard !visible.isNull, !visible.isEmpty else { return nil }
        // Inverse of max(viewportWidth / pixelWidth, viewportHeight / pixelHeight).
        let inverseScale = min(pixels.width / viewport.width, pixels.height / viewport.height)
        let offsetX = (pixels.width - viewport.width * inverseScale) / 2
        let offsetY = (pixels.height - viewport.height * inverseScale) / 2
        let minX = visible.minX * inverseScale + offsetX
        let minY = visible.minY * inverseScale + offsetY
        let maxX = visible.maxX * inverseScale + offsetX
        let maxY = visible.maxY * inverseScale + offsetY
        guard inverseScale.isFinite, inverseScale > 0,
              [minX, minY, maxX, maxY].allSatisfy(\.isFinite) else { return nil }
        let bounds = CGRect(origin: .zero, size: pixels)
        let mapped = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).intersection(bounds)
        guard !mapped.isNull, !mapped.isEmpty else { return nil }
        let rounded = mapped.integral.intersection(bounds)
        return rounded.isNull || rounded.isEmpty ? nil : rounded
    }

    static func clamp(_ point: CGPoint, viewport: CGSize) -> CGPoint? {
        guard valid(viewport), point.x.isFinite, point.y.isFinite else { return nil }
        return CGPoint(x: min(max(point.x, 0), viewport.width),
                       y: min(max(point.y, 0), viewport.height))
    }

    private static func valid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0
    }
}
