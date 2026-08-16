import AppKit
import ApplicationServices

/// Selects the whitespace-delimited word before the caret using the
/// Accessibility API. A word is a maximal run of non-whitespace characters;
/// boundaries are spaces, tabs, and newlines — no other characters split a
/// word. This is the precise counterpart to the ⌥⇧← fallback, which uses the
/// OS word definition where punctuation is a boundary.
enum WholeWordSelection {

    /// Select the maximal run of non-whitespace characters ending at the
    /// caret in the focused text element and return its text. When the caret
    /// rests on whitespace, the word before it is selected instead. Returns
    /// nil when the focused app does not expose the required AX attributes or
    /// when there is no word before the caret.
    static func selectWordBeforeCaret() -> String? {
        guard let element = focusedElement() else {
            TextSwitcher.diag("AX: no focused element")
            return nil
        }
        guard let caretIndex = caretIndex(in: element) else {
            TextSwitcher.diag("AX: no caret index")
            return nil
        }
        TextSwitcher.diag("AX: caret=\(caretIndex)")

        // Line-based approach: works in Cocoa apps (TextEdit, Telegram). Some
        // browsers don't expose AXLineForIndex/AXRangeForLine, so this can
        // fail there and we fall back to the full-text approach below.
        if let lineRange = lineRange(containing: caretIndex, in: element),
           let lineText = lineText(for: lineRange, in: element) {
            TextSwitcher.diag("AX: line=\(lineRange.location),\(lineRange.length) text=\(lineText.prefix(80))")
            let caretInLine = caretIndex - lineRange.location
            guard let token = tokenRange(for: lineText, caretInLine: caretInLine) else { return nil }
            let range = CFRange(location: lineRange.location + token.lowerBound, length: token.count)
            guard select(range: range, in: element) else { return nil }
            return String(Array(lineText)[token])
        }
        TextSwitcher.diag("AX: line-based failed")

        // Fallback: full text via AXValue. Browsers (Chromium/WebKit) expose
        // the value even when the line-based parameterized attributes are
        // missing, so the whitespace-delimited word is still selectable.
        guard let fullText = fullText(of: element) else {
            TextSwitcher.diag("AX: no AXValue")
            return nil
        }
        TextSwitcher.diag("AX: value=\(fullText.prefix(80))")
        guard let token = tokenRange(for: fullText, caretInLine: caretIndex) else { return nil }
        guard select(range: CFRange(location: token.lowerBound, length: token.count), in: element) else { return nil }
        return String(Array(fullText)[token])
    }

    /// Set the element's selected text range. Returns false when the app
    /// rejects the range.
    private static func select(range: CFRange, in element: AXUIElement) -> Bool {
        var selection = range
        guard let selectionValue = AXValueCreate(.cfRange, &selection) else { return false }
        return AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            selectionValue
        ) == .success
    }

    /// The element's full text via `AXValue`, or nil when the element does
    /// not expose it (e.g. a container without a value).
    private static func fullText(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success,
              let value else { return nil }
        return value as? String
    }

    /// The maximal run of non-whitespace characters ending at `caretInLine`
    /// within `lineText`. When the caret sits on whitespace, the run ending
    /// just before that whitespace is returned instead — a word is always
    /// surrounded by whitespace, so the caret may rest on the trailing space.
    /// Returns nil when there is no word before the caret (line start or only
    /// whitespace ahead of it).
    static func tokenRange(for lineText: String, caretInLine: Int) -> Range<Int>? {
        let chars = Array(lineText)
        guard caretInLine > 0, caretInLine <= chars.count else { return nil }
        var end = caretInLine
        while end > 0 && chars[end - 1].isWhitespace {
            end -= 1
        }
        guard end > 0 else { return nil }
        var start = end
        while start > 0 && !chars[start - 1].isWhitespace {
            start -= 1
        }
        return start..<end
    }

    // MARK: - AX helpers

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let systemErr = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        TextSwitcher.diag("AX focusedElement: system err=\(systemErr.rawValue) value=\(focused != nil)")
        if systemErr == .success, let focused {
            // CF types are toll-free bridged through CFTypeRef; the cast is safe.
            // swiftlint:disable:next force_cast
            return focused as! AXUIElement
        }

        // Some apps (Chromium-based browsers) don't report a focused element
        // to the system-wide query. Ask the frontmost app directly.
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let app = AXUIElementCreateApplication(pid)
        var appFocused: CFTypeRef?
        let appErr = AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &appFocused)
        TextSwitcher.diag("AX focusedElement: app err=\(appErr.rawValue) value=\(appFocused != nil)")
        guard appErr == .success, let appFocused else { return nil }
        // swiftlint:disable:next force_cast
        return appFocused as! AXUIElement
    }

    private static func caretIndex(in element: AXUIElement) -> Int? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &value) == .success,
              let value else { return nil }
        var range = CFRange()
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(value as! AXValue, .cfRange, &range) else { return nil }
        return range.location
    }

    private static func lineRange(containing index: Int, in element: AXUIElement) -> CFRange? {
        var lineNumberValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXLineForIndexParameterizedAttribute as CFString,
            NSNumber(value: index),
            &lineNumberValue
        ) == .success, let lineNumberValue, let lineNumber = (lineNumberValue as? NSNumber)?.intValue else { return nil }

        var lineRangeValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXRangeForLineParameterizedAttribute as CFString,
            NSNumber(value: lineNumber),
            &lineRangeValue
        ) == .success, let lineRangeValue else { return nil }
        var lineRange = CFRange()
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(lineRangeValue as! AXValue, .cfRange, &lineRange) else { return nil }
        return lineRange
    }

    private static func lineText(for range: CFRange, in element: AXUIElement) -> String? {
        var rangeValue = range
        guard let parameter = AXValueCreate(.cfRange, &rangeValue) else { return nil }
        var textValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            parameter,
            &textValue
        ) == .success, let textValue else { return nil }
        return textValue as? String
    }
}
