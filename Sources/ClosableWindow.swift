import Cocoa

final class ClosableWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        // Key-code based so the editing shortcuts work in any keyboard layout:
        // charactersIgnoringModifiers changes with the active layout (e.g. the
        // Cyrillic layout turns the A key into 'ф'), but the physical letter
        // key codes are identical across ANSI/ISO/JIS.
        switch event.keyCode {
        case 13: // W
            performClose(nil)
            return true
        case 0: // A
            return performEditingAction(#selector(NSText.selectAll(_:)), with: event)
        case 8: // C
            return performEditingAction(#selector(NSText.copy(_:)), with: event)
        case 7: // X
            return performEditingAction(#selector(NSText.cut(_:)), with: event)
        case 9: // V
            return performEditingAction(#selector(NSText.paste(_:)), with: event)
        case 6: // Z
            let selector: Selector = event.modifierFlags.contains(.shift)
                ? Selector(("redo:"))
                : Selector(("undo:"))
            return performEditingAction(selector, with: event)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    private func performEditingAction(_ selector: Selector, with event: NSEvent) -> Bool {
        // Route directly through the responder chain from the first responder:
        // NSApp.sendAction(_:to: nil) fails to resolve a target here because the
        // sender is an NSEvent, not a view.
        if firstResponder?.tryToPerform(selector, with: event) == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
