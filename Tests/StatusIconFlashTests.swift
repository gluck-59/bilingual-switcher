import XCTest
import AppKit

final class StatusIconFlashTests: XCTestCase {

    /// A minimal template glyph shaped like the real menu-bar icon: a
    /// horizontal black band in the middle of a 32×32 transparent canvas.
    private func makeTemplateBase() -> NSImage {
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.isTemplate = true
        image.lockFocus()
        NSColor.black.setFill()
        NSRect(x: 4, y: 12, width: 24, height: 8).fill()
        image.unlockFocus()
        return image
    }

    private func makeFlash(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage? {
        AppDelegate.makeFlashImage(
            base: makeTemplateBase(),
            size: size,
            background: NSColor(
                deviceRed: 1.0, green: 150.0 / 255.0, blue: 0.0, alpha: 1.0
            ),
            cornerRadius: 4,
            inset: 1
        )
    }

    /// Sample a color at a point in points (the rep is rendered at 2x).
    private func pixel(_ image: NSImage, point: CGPoint) -> NSColor? {
        guard let rep = image.representations.first as? NSBitmapImageRep else { return nil }
        let x = Int(point.x * 2)
        let y = Int(point.y * 2)
        guard x >= 0, x < rep.pixelsWide, y >= 0, y < rep.pixelsHigh else { return nil }
        return rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
    }

    private func isClose(_ value: CGFloat, to expected: CGFloat, tolerance: CGFloat = 0.05) -> Bool {
        abs(value - expected) <= tolerance
    }

    // MARK: - Basic properties

    func testMakeFlash_ReturnsNonNilForValidInput() {
        XCTAssertNotNil(makeFlash())
    }

    func testMakeFlash_HasRequestedPointSize() {
        let image = makeFlash()
        XCTAssertEqual(image?.size.width, 18)
        XCTAssertEqual(image?.size.height, 18)
    }

    func testMakeFlash_IsNotATemplate() {
        XCTAssertEqual(makeFlash()?.isTemplate, false)
    }

    func testMakeFlash_ReturnsNilForZeroSize() {
        XCTAssertNil(makeFlash(size: .zero))
    }

    func testMakeFlash_ReturnsNilForNegativeSize() {
        XCTAssertNil(makeFlash(size: NSSize(width: -18, height: 18)))
    }

    // MARK: - Pixel colors

    func testMakeFlash_FillIsOrange() {
        guard let image = makeFlash() else { return XCTFail("flash image nil") }
        // Top-center: inside the rounded fill (inset 1, starts at y=1) but
        // above the glyph band (which starts near y=7).
        guard let color = pixel(image, point: CGPoint(x: 9, y: 2.5)) else {
            return XCTFail("no pixel data")
        }
        XCTAssertTrue(isClose(color.redComponent, to: 1.0), "red was \(color.redComponent)")
        XCTAssertTrue(isClose(color.greenComponent, to: 150.0 / 255.0), "green was \(color.greenComponent)")
        XCTAssertTrue(isClose(color.blueComponent, to: 0.0), "blue was \(color.blueComponent)")
        XCTAssertTrue(isClose(color.alphaComponent, to: 1.0), "alpha was \(color.alphaComponent)")
    }

    func testMakeFlash_GlyphIsWhite() {
        guard let image = makeFlash() else { return XCTFail("flash image nil") }
        // Center: inside the glyph band (y 7...11).
        guard let color = pixel(image, point: CGPoint(x: 9, y: 9)) else {
            return XCTFail("no pixel data")
        }
        XCTAssertTrue(isClose(color.redComponent, to: 1.0), "red was \(color.redComponent)")
        XCTAssertTrue(isClose(color.greenComponent, to: 1.0), "green was \(color.greenComponent)")
        XCTAssertTrue(isClose(color.blueComponent, to: 1.0), "blue was \(color.blueComponent)")
        XCTAssertTrue(isClose(color.alphaComponent, to: 1.0), "alpha was \(color.alphaComponent)")
    }

    func testMakeFlash_RoundedCornersAreTransparent() {
        guard let image = makeFlash() else { return XCTFail("flash image nil") }
        // The rounded corner cuts the 1×1 image corner away from the fill.
        guard let color = pixel(image, point: CGPoint(x: 1, y: 1)) else {
            return XCTFail("no pixel data")
        }
        XCTAssertTrue(color.alphaComponent < 0.05, "alpha was \(color.alphaComponent)")
    }
}
