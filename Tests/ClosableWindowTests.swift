import Cocoa
import XCTest

final class ClosableWindowTests: XCTestCase {

    private func makeKeyWindow(field: NSTextField) -> ClosableWindow {
        _ = NSApplication.shared
        let window = ClosableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        field.frame = NSRect(x: 20, y: 80, width: 360, height: 24)
        window.contentView?.addSubview(field)
        window.makeKeyAndOrderFront(nil)
        return window
    }

    /// The `characters`/`charactersIgnoringModifiers` are deliberately Cyrillic
    /// to prove the shortcuts are keyed on the physical key, not the layout.
    private func commandEvent(keyCode: UInt16, characters: String, window: NSWindow) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )!
    }

    func testCommandASelectsAllUnderAnyLayout() throws {
        let field = NSTextField(string: "some text in the license field")
        let window = makeKeyWindow(field: field)
        defer { window.orderOut(nil) }
        window.makeFirstResponder(field)
        let editor = try XCTUnwrap(field.currentEditor())

        // 'A' physical key (keyCode 0); 'ф' is what it produces under Cyrillic.
        XCTAssertTrue(window.performKeyEquivalent(with: commandEvent(keyCode: 0, characters: "ф", window: window)))
        XCTAssertEqual(editor.selectedRange, NSRange(location: 0, length: field.stringValue.count))
    }

    func testCommandVPastesUnderAnyLayout() throws {
        let field = NSTextField(string: "")
        let window = makeKeyWindow(field: field)
        defer { window.orderOut(nil) }
        window.makeFirstResponder(field)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("pasted-key", forType: .string)

        // 'V' physical key (keyCode 9); 'м' is what it produces under Cyrillic.
        XCTAssertTrue(window.performKeyEquivalent(with: commandEvent(keyCode: 9, characters: "м", window: window)))
        XCTAssertEqual(field.stringValue, "pasted-key")
    }

    func testCommandAWithoutEditableFocusIsNotHandled() {
        let field = NSTextField(string: "text")
        let button = NSButton(title: "Save", target: nil, action: nil)
        let window = makeKeyWindow(field: field)
        defer { window.orderOut(nil) }
        button.frame = NSRect(x: 20, y: 20, width: 100, height: 28)
        window.contentView?.addSubview(button)
        window.makeFirstResponder(button)

        // A button has no selectAll: — the window must not claim the event.
        XCTAssertFalse(window.performKeyEquivalent(with: commandEvent(keyCode: 0, characters: "a", window: window)))
    }
}
