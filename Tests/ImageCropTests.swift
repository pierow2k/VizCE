import XCTest

final class ImageCropTests: XCTestCase {
    func testMatchingAspectRatioUsesPixelDimensions() {
        let result = ImageCropTransform.map(
            selection: CGRect(x: 100, y: 50, width: 200, height: 100),
            viewport: CGSize(width: 800, height: 600),
            pixels: CGSize(width: 1_600, height: 1_200)
        )
        XCTAssertEqual(result, CGRect(x: 200, y: 100, width: 400, height: 200))
    }

    func test1920By1080In800By600IncludesHorizontalCropOffset() {
        let viewport = CGSize(width: 800, height: 600)
        let pixels = CGSize(width: 1_920, height: 1_080)
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(x: 0, y: 0, width: 100, height: 600),
                viewport: viewport,
                pixels: pixels
            ),
            CGRect(x: 240, y: 0, width: 180, height: 1_080)
        )
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(origin: .zero, size: viewport),
                viewport: viewport,
                pixels: pixels
            ),
            CGRect(x: 240, y: 0, width: 1_440, height: 1_080)
        )
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(x: 100, y: 100, width: 200, height: 200),
                viewport: viewport,
                pixels: pixels
            ),
            CGRect(x: 420, y: 180, width: 360, height: 360)
        )
    }

    func testTallImageIncludesVerticalCropOffset() {
        let viewport = CGSize(width: 800, height: 600)
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(origin: .zero, size: viewport),
                viewport: viewport,
                pixels: CGSize(width: 1_080, height: 1_920)
            ),
            CGRect(x: 0, y: 555, width: 1_080, height: 810)
        )
    }

    func testReversedAndOutOfBoundsSelectionsAreIntersected() {
        let size = CGSize(width: 100, height: 100)
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(x: 70, y: 80, width: -50, height: -60),
                viewport: size,
                pixels: size
            ),
            CGRect(x: 20, y: 20, width: 50, height: 60)
        )
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(x: -20, y: -10, width: 80, height: 70),
                viewport: size,
                pixels: size
            ),
            CGRect(x: 0, y: 0, width: 60, height: 60)
        )
    }

    func testFractionalSelectionRoundsOutward() {
        let size = CGSize(width: 100, height: 100)
        XCTAssertEqual(
            ImageCropTransform.map(
                selection: CGRect(x: 10.2, y: 15.8, width: 5.2, height: 3.4),
                viewport: size,
                pixels: size
            ),
            CGRect(x: 10, y: 15, width: 6, height: 5)
        )
    }

    func testInvalidAndOutsideSelectionsAreRejected() {
        let size = CGSize(width: 100, height: 100)
        for rect in [
            CGRect.zero, CGRect(x: 150, y: 150, width: 20, height: 20),
            CGRect(x: CGFloat.nan, y: 0, width: 10, height: 10),
            CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 10),
        ] {
            XCTAssertNil(ImageCropTransform.map(selection: rect, viewport: size, pixels: size))
        }
        for invalid in [CGSize.zero, CGSize(width: -1, height: 100), CGSize(width: CGFloat.infinity, height: 100)] {
            XCTAssertNil(
                ImageCropTransform.map(
                    selection: CGRect(x: 1, y: 1, width: 10, height: 10),
                    viewport: invalid,
                    pixels: size
                )
            )
            XCTAssertNil(
                ImageCropTransform.map(
                    selection: CGRect(x: 1, y: 1, width: 10, height: 10),
                    viewport: size,
                    pixels: invalid
                )
            )
        }
    }

    func testGestureClampingAndResizeOrImageResetInvalidation() {
        var selection = ImageSelectionState()
        selection.updateViewport(CGSize(width: 800, height: 600))
        selection.drag(start: CGPoint(x: 850, y: 700), current: CGPoint(x: -20, y: 100))
        XCTAssertEqual(selection.rect, CGRect(x: 0, y: 100, width: 800, height: 500))
        XCTAssertTrue(selection.isDragging)
        selection.updateViewport(CGSize(width: 600, height: 400))
        XCTAssertEqual(selection.rect, .zero)
        XCTAssertFalse(selection.isDragging)
        selection.drag(start: CGPoint(x: 20, y: 20), current: CGPoint(x: 50, y: 80))
        XCTAssertEqual(selection.rect, CGRect(x: 20, y: 20, width: 30, height: 60))
        selection.clear()  // The captured-image change uses the same reset.
        XCTAssertEqual(selection.rect, .zero)
        XCTAssertFalse(selection.isDragging)
    }
}
