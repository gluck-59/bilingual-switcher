import ApplicationServices

/// Selects the whitespace-delimited word before the caret using the
/// Accessibility API. A word is a maximal run of non-whitespace characters;
/// boundaries are spaces, tabs, and newlines — no other characters split a
/// word. This is the precise counterpart to the ⌥⇧← fallback, which uses the
/// OS word definition where punctuation is a boundary.
enum WholeWordSelection {

    /// Select the maximal run of non-whitespace characters ending at the
    /// caret in the focused text element and return its text. Returns nil
    /// when the focused app does not expose the required AX attributes or
    /// when the token is empty (caret right after whitespace or at the start
    /// of a line).
    static func selectWordBeforeCaret() -> String? {
        guard let element = focusedElement() else { return nil }
        guard let caretIndex = caretIndex(in: element) else { return nil }
        guard let lineRange = lineRange(containing: caretIndex, in: element) else { return nil }
        guard let lineText = lineText(for: lineRange, in: element) else { return nil }

        let caretInLine = caretIndex - lineRange.location
        guard let token = tokenRange(for: lineText, caretInLine: caretInLine) else { return nil }

        var selection = CFRange(location: lineRange.location + token.lowerBound, length: token.count)
        guard let selectionValue = AXValueCreate(.cfRange, &selection) else { return nil }
        guard AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            selectionValue
        ) == .success else { return nil }

        return String(Array(lineText)[token])
    }

    /// The maximal run of non-whitespace characters ending at `caretInLine`
    /// within `lineText`. Returns nil when the caret sits on whitespace or at
    /// the start of the line, so there is no word to select.
    static func tokenRange(for lineText: String, caretInLine: Int) -> Range<Int>? {
        let chars = Array(lineText)
        guard caretInLine > 0, caretInLine <= chars.count else { return nil }
        var tokenStart = caretInLine
        while tokenStart > 0 && !chars[tokenStart - 1].isWhitespace {
            tokenStart -= 1
        }
        guard tokenStart < caretInLine else { return nil }
        return tokenStart..<caretInLine
    }

    // MARK: - AX helpers

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused else { return nil }
        // CF types are toll-free bridged through CFTypeRef; the cast is safe.
        // swiftlint:disable:next force_cast
        return focused as! AXUIElement
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
