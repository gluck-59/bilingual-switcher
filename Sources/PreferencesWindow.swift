import Cocoa
import Carbon
import ServiceManagement

class PreferencesWindowController: NSWindowController {
    private let onHotkeyChanged: () -> Void
    @IBOutlet private var recorderView: ShortcutRecorderView!
    @IBOutlet private var switchLayoutCheckbox: NSButton!
    @IBOutlet private var launchAtLoginCheckbox: NSButton!
    private var currentKeyCode: UInt32
    private var currentModifiers: UInt32

    init(onHotkeyChanged: @escaping () -> Void) {
        self.onHotkeyChanged = onHotkeyChanged
        self.currentKeyCode = UserDefaults.standard.hotkeyKeyCode
        self.currentModifiers = UserDefaults.standard.hotkeyModifiers
        super.init(window: nil)
        loadNib()
        configureControls()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func loadNib() {
        var topLevelObjects: NSArray?
        guard let nib = NSNib(nibNamed: "PreferencesWindow", bundle: .main),
              nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects) else {
            fatalError("Failed to load PreferencesWindow nib")
        }
    }

    private func configureControls() {
        window?.center()
        window?.isReleasedWhenClosed = false
        refreshControls()
    }

    /// Re-sync every control (recorder, checkboxes) from persisted state,
    /// discarding any in-memory edits. Called once at init and again every time
    /// the window is shown, so a cancelled session cannot leak stale values
    /// into the next open (which made Cancel look like Save).
    private func refreshControls() {
        currentKeyCode = UserDefaults.standard.hotkeyKeyCode
        currentModifiers = UserDefaults.standard.hotkeyModifiers

        recorderView.configure(keyCode: currentKeyCode, modifiers: currentModifiers) { [weak self] keyCode, modifiers in
            self?.currentKeyCode = keyCode
            self?.currentModifiers = modifiers
        }
        switchLayoutCheckbox.state = UserDefaults.standard.switchLayoutAfterConversion ? .on : .off
        launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    override func showWindow(_ sender: Any?) {
        if window?.isVisible != true {
            refreshControls()
        }
        super.showWindow(sender)
    }

    @objc private func savePreferences(_ sender: Any?) {
        UserDefaults.standard.hotkeyKeyCode = currentKeyCode
        UserDefaults.standard.hotkeyModifiers = currentModifiers

        UserDefaults.standard.switchLayoutAfterConversion = switchLayoutCheckbox.state == .on

        let wantsLaunchAtLogin = launchAtLoginCheckbox.state == .on
        LaunchAtLogin.isEnabled = wantsLaunchAtLogin

        onHotkeyChanged()
        window?.close()
    }

    @objc private func cancelPreferences(_ sender: Any?) {
        window?.close()
    }
}

// MARK: - Shortcut Recorder View

class ShortcutRecorderView: NSView {
    /// A decided recording outcome, consolidated so `commit` has one entry
    /// point. A keyed hotkey comes straight from `keyDown`; a modifier-only
    /// combo comes from `flagsChanged` once a valid (≥2-modifier) peak set is
    /// released to empty. The validity rule itself lives in and is tested via
    /// `HotkeyModifierHelper.isValidModifierOnlyCombo`.
    enum RecorderCapture: Equatable {
        case keyed(keyCode: UInt32, modifiers: UInt32)
        case modifierOnly(modifiers: UInt32)
    }

    private var keyCode: UInt32
    private var modifiers: UInt32
    private var isRecording = false
    private var peakCarbonModifiers: UInt32 = 0
    private var displayText: String
    private var displayColor: NSColor = .labelColor
    private var onChange: (UInt32, UInt32) -> Void

    init(frame: NSRect, keyCode: UInt32, modifiers: UInt32, onChange: @escaping (UInt32, UInt32) -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayText = ""
        self.onChange = onChange
        super.init(frame: frame)
        setupView()
    }

    override init(frame: NSRect) {
        self.keyCode = UserDefaults.standard.hotkeyKeyCode
        self.modifiers = UserDefaults.standard.hotkeyModifiers
        self.displayText = ""
        self.onChange = { _, _ in }
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.keyCode = UserDefaults.standard.hotkeyKeyCode
        self.modifiers = UserDefaults.standard.hotkeyModifiers
        self.displayText = ""
        self.onChange = { _, _ in }
        super.init(coder: coder)
        setupView()
    }

    /// Wire up the values and change callback after the view is loaded from a
    /// nib, where init(coder:) cannot receive them.
    func configure(keyCode: UInt32, modifiers: UInt32, onChange: @escaping (UInt32, UInt32) -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.onChange = onChange
        displayText = shortcutString()
        needsDisplay = true
    }

    override var acceptsFirstResponder: Bool { true }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        applyLayerColors()
        displayText = shortcutString()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let text = displayText as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: displayColor
        ]
        let size = text.size(withAttributes: attributes)
        let point = NSPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        text.draw(at: point, withAttributes: attributes)
    }

    /// Re-resolve the layer's background and border against the view's *own*
    /// effective appearance. A CALayer holds plain CGColors, which — unlike the
    /// dynamic NSColors they come from — never re-resolve when the system flips
    /// between light and dark. `NSColor.cgColor` bakes in whatever appearance is
    /// current at that instant (the default light/aqua appearance during
    /// `init`), which is why the field rendered as a solid white box in dark
    /// mode. Wrapping in `performAsCurrent` resolves against the view's real
    /// appearance, and re-running from `viewDidChangeEffectiveAppearance`
    /// keeps it correct when the user toggles the system theme live.
    private func applyLayerColors() {
        let update: () -> Void = {
            self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            let border = self.isRecording ? NSColor.systemGreen : NSColor.separatorColor
            self.layer?.borderColor = border.cgColor
        }
        if #available(macOS 11.0, *) {
            effectiveAppearance.performAsCurrentDrawingAppearance(update)
        } else {
            update()
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyLayerColors()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        peakCarbonModifiers = 0
        displayText = "Выберите сочетание клавиш"
        displayColor = .systemGreen
        needsDisplay = true
        layer?.borderWidth = 2
        applyLayerColors()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let carbonModifiers = event.carbonModifiers
        guard carbonModifiers != 0 else { return }

        // A real key press always wins: record a keyed hotkey immediately.
        commit(.keyed(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers))
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }

        let currentCarbon = event.carbonModifiers
        if currentCarbon != 0 {
            // Each flagsChanged carries the *complete* currently-held set, so
            // keep the largest simultaneously-held set (most modifiers) rather
            // than OR-ing across the whole gesture. A rolling press (⌘ down,
            // ⌘ up, ⌥ down — never both down together) must not record ⌥⌘.
            if currentCarbon.nonzeroBitCount > peakCarbonModifiers.nonzeroBitCount {
                peakCarbonModifiers = currentCarbon
            }
            return
        }

        // Flags fell back to empty. Recording is still active here — a keyed
        // press would have committed and set isRecording=false, which the guard
        // above already catches — so a valid peak set is a modifier-only tap.
        if HotkeyModifierHelper.isValidModifierOnlyCombo(carbonModifiers: peakCarbonModifiers) {
            commit(.modifierOnly(modifiers: peakCarbonModifiers))
        } else {
            // A lone modifier is not enough — stay recording and let the user
            // try again from a clean peak.
            peakCarbonModifiers = 0
        }
    }

    /// Applies a decided capture: stores the values, ends recording, refreshes
    /// the display and notifies the owner.
    private func commit(_ capture: RecorderCapture) {
        switch capture {
        case .keyed(let code, let combo):
            keyCode = code
            modifiers = combo
        case .modifierOnly(let combo):
            keyCode = HotkeyManager.modifierOnlyKeyCode
            modifiers = combo
        }

        isRecording = false
        displayText = shortcutString()
        displayColor = .labelColor
        needsDisplay = true
        layer?.borderWidth = 1
        applyLayerColors()

        onChange(keyCode, modifiers)
    }

    private func shortcutString() -> String {
        HotkeyDisplayHelper.format(keyCode: keyCode, modifiers: modifiers)
    }
}

// MARK: - NSEvent Carbon modifier conversion

extension NSEvent {
    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        if modifierFlags.contains(.control) { carbon |= UInt32(controlKey) }
        if modifierFlags.contains(.option) { carbon |= UInt32(optionKey) }
        if modifierFlags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifierFlags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}

// MARK: - Hotkey display formatting

enum HotkeyDisplayHelper {
    static func format(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        if keyCode != HotkeyManager.modifierOnlyKeyCode {
            parts.append(KeyCodeNames.name(for: keyCode))
        }
        return parts.joined()
    }
}

// MARK: - Launch at Login

enum LaunchAtLogin {
    static var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    NSLog("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
                }
            }
            UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
        }
    }
}
