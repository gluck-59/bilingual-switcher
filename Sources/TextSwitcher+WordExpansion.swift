import AppKit
import Carbon

extension TextSwitcher {

    /// Maximum number of ⌥⇧← presses in the greedy word-expansion fallback.
    /// Each press extends the selection to the previous word boundary; the
    /// loop normally stops after 2–3 presses (whitespace or no growth), this
    /// is a safety cap for apps with unusual ⌥⇧← behavior.
    private static let maxWordExpansionPresses = 6

    /// Fallback when AX is unavailable: select the word before the caret with
    /// ⌥⇧←, then keep extending the selection across punctuation (comma,
    /// semicolon) until the added prefix contains whitespace or the selection
    /// stops growing. This reproduces the whitespace-delimited word semantics
    /// of the AX path without depending on AX, so words like `hf,jnftn` are
    /// selected whole instead of being split at the comma.
    func greedyWordExpansionAndConvert(
        savedItems: [[NSPasteboard.PasteboardType: Data]],
        pasteboard: NSPasteboard,
        frontBundleID: String?
    ) {
        Self.simulateKeyStroke(keyCode: CGKeyCode(kVK_LeftArrow), flags: [.maskAlternate, .maskShift])
        Thread.sleep(forTimeInterval: 0.02)

        guard var current = Self.copySelectionSync(pasteboard: pasteboard), !current.isEmpty else {
            Self.diag("greedy: no text after first ⌥⇧←")
            NSSound.beep()
            Self.restoreClipboard(savedItems, to: pasteboard)
            return
        }
        Self.diag("greedy: initial=\(current.prefix(80))")

        for press in 1...Self.maxWordExpansionPresses {
            Self.simulateKeyStroke(keyCode: CGKeyCode(kVK_LeftArrow), flags: [.maskAlternate, .maskShift])
            Thread.sleep(forTimeInterval: 0.02)
            guard let next = Self.copySelectionSync(pasteboard: pasteboard), !next.isEmpty else {
                Self.diag("greedy: no growth on press \(press)")
                break
            }

            let currentTrimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextTrimmed = next.trimmingCharacters(in: .whitespacesAndNewlines)
            guard nextTrimmed.count > currentTrimmed.count,
                  nextTrimmed.hasSuffix(currentTrimmed) else {
                Self.diag("greedy: no strict growth on press \(press)")
                break
            }

            let addedPrefix = nextTrimmed.dropLast(currentTrimmed.count)
            if addedPrefix.contains(where: { $0.isWhitespace }) {
                // Crossed into the previous word — shrink back one word.
                Self.diag("greedy: whitespace in prefix on press \(press), shrinking")
                Self.simulateKeyStroke(keyCode: CGKeyCode(kVK_RightArrow), flags: [.maskAlternate, .maskShift])
                Thread.sleep(forTimeInterval: 0.02)
                guard let shrunk = Self.copySelectionSync(pasteboard: pasteboard), !shrunk.isEmpty else {
                    Self.diag("greedy: shrink produced no text — bailing")
                    NSSound.beep()
                    Self.restoreClipboard(savedItems, to: pasteboard)
                    return
                }
                let shrunkTrimmed = shrunk.trimmingCharacters(in: .whitespacesAndNewlines)
                guard nextTrimmed.hasSuffix(shrunkTrimmed), shrunkTrimmed.count < nextTrimmed.count else {
                    Self.diag("greedy: shrink failed — bailing")
                    NSSound.beep()
                    Self.restoreClipboard(savedItems, to: pasteboard)
                    return
                }
                current = shrunk
                Self.diag("greedy: shrunk to \(current.prefix(80))")
                break
            }

            current = next
            Self.diag("greedy: extended to \(current.prefix(80))")
        }

        self.completeConversion(
            copied: true,
            copiedText: current,
            savedItems: savedItems,
            pasteboard: pasteboard,
            frontBundleID: frontBundleID
        )
    }

    /// Post Cmd+C and wait synchronously (spinning the main run loop) for the
    /// focused app to fill the pasteboard. Returns the copied string, or nil
    /// on timeout. Used by the greedy word-expansion loop, which needs the
    /// selection text at each step before deciding whether to extend further.
    private static func copySelectionSync(pasteboard: NSPasteboard) -> String? {
        let baselineChangeCount = pasteboard.changeCount
        Self.simulateKeyStroke(keyCode: CGKeyCode(kVK_ANSI_C), flags: .maskCommand)
        let deadline = Date().addingTimeInterval(Self.copyTimeout)
        while Date() < deadline {
            if pasteboard.changeCount != baselineChangeCount {
                return pasteboard.string(forType: .string)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.copyPollInterval))
        }
        return pasteboard.string(forType: .string)
    }
}
