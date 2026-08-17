import Cocoa
import Carbon
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager!
    private var textSwitcher: TextSwitcher!
    private var preferencesWindow: PreferencesWindowController?
    private var aboutWindow: AboutWindowController?
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        textSwitcher = TextSwitcher()
        textSwitcher.onConversionSucceeded = { [weak self] in
            self?.flashStatusIcon()
        }
        hotkeyManager = HotkeyManager { [weak self] in
            self?.textSwitcher.switchSelectedText()
        }
        hotkeyManager.register()

        KeyboardLayoutMap.startObservingLayoutChanges()
        setupMenuBar()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }

        if let button = statusItem.button {
            button.toolTip = "ЯR Switcher"
            button.setAccessibilityLabel("ЯR Switcher")
            if let iconPath = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
               let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else if #available(macOS 11.0, *), let image = NSImage(
                systemSymbolName: "keyboard.badge.ellipsis",
                accessibilityDescription: "ЯR Switcher"
            ) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "ЯR"
            }
        }

        let menu = NSMenu()

        let switchItem = NSMenuItem(title: "Переключить выделенный текст", action: #selector(switchText), keyEquivalent: "")
        switchItem.target = self
        menu.addItem(switchItem)

        menu.addItem(NSMenuItem.separator())

        let hotkeyInfo = NSMenuItem()
        hotkeyInfo.isEnabled = false
        hotkeyInfo.attributedTitle = hotkeyAttributedDescription()
        menu.addItem(hotkeyInfo)

        menu.addItem(NSMenuItem.separator())

        let checkUpdatesItem = NSMenuItem(
            title: "Проверить обновления",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = updaterController
        menu.addItem(checkUpdatesItem)

        let prefsItem = NSMenuItem(title: "Настройки", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let aboutItem = NSMenuItem(
            title: "О программе",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Выход", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func hotkeyAttributedDescription() -> NSAttributedString {
        let prefix = "Горячая клавиша: "
        let hotkey = HotkeyDisplayHelper.format(
            keyCode: UserDefaults.standard.hotkeyKeyCode,
            modifiers: UserDefaults.standard.hotkeyModifiers
        )
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: prefix, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]))
        result.append(NSAttributedString(string: hotkey, attributes: [
            .font: NSFont.boldSystemFont(ofSize: 24)
        ]))
        return result
    }

    // MARK: - Status icon flash

    /// How long the flash image stays on the status button before the
    /// original template icon is restored.
    private static let flashDuration: TimeInterval = 0.3

    /// Flash background color: RGB 255, 150, 0.
    private static let flashBackgroundColor = NSColor(
        deviceRed: 1.0, green: 150.0 / 255.0, blue: 0.0, alpha: 1.0
    )

    /// Corner radius (points) of the rounded-square flash fill.
    private static let flashCornerRadius: CGFloat = 4

    /// Inset (points) between the rounded fill and the icon's edge.
    private static let flashInset: CGFloat = 1

    /// Restore work currently scheduled, cancelled when a newer flash
    /// supersedes it so rapid successive hotkeys never restore early.
    private var flashRestoreWork: DispatchWorkItem?
    /// The template icon the flash temporarily replaced.
    private var flashBaseImage: NSImage?

    /// Briefly swap the status-button icon for an orange-background version
    /// after a successful conversion, then restore the template icon. Runs on
    /// the main thread (the conversion flow completes there).
    private func flashStatusIcon() {
        guard let button = statusItem?.button, let base = button.image else { return }
        flashRestoreWork?.cancel()
        flashBaseImage = base

        // Defer the swap to the next main-runloop turn so the 300 ms hold
        // starts only after the synchronous conversion flow returns and the
        // button actually repaints.
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let flash = Self.makeFlashImage(
                      base: base,
                      size: NSSize(width: 18, height: 18),
                      background: Self.flashBackgroundColor,
                      cornerRadius: Self.flashCornerRadius,
                      inset: Self.flashInset
                  )
            else { return }
            button.image = flash
            button.image?.isTemplate = false

            let work = DispatchWorkItem { [weak self] in
                guard let self, let button = self.statusItem?.button else { return }
                if let base = self.flashBaseImage {
                    button.image = base
                    button.image?.isTemplate = true
                }
                self.flashRestoreWork = nil
            }
            self.flashRestoreWork = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Self.flashDuration,
                execute: work
            )
        }
    }

    /// Composite a rounded orange square behind a white copy of the template
    /// glyph. The result is non-template so it renders identically in both
    /// light and dark menu bars. Rendered at 2x pixel scale for retina.
    static func makeFlashImage(
        base: NSImage,
        size: NSSize,
        background: NSColor,
        cornerRadius: CGFloat,
        inset: CGFloat
    ) -> NSImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let pixelsWide = Int(size.width * 2)
        let pixelsHigh = Int(size.height * 2)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        rep.size = size

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context

        let rect = NSRect(origin: .zero, size: size)
        let fillRect = rect.insetBy(dx: inset, dy: inset)

        // Tint the glyph white on a transparent canvas first, so the white
        // never bleeds into the orange fill (sourceAtop over the opaque
        // background would whiten the whole square).
        let glyph = Self.whiteGlyph(from: base, in: fillRect)

        let rounded = NSBezierPath(
            roundedRect: fillRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )
        background.setFill()
        rounded.fill()

        glyph.draw(in: fillRect)

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    /// Render `base` as a white glyph on a transparent canvas sized to `rect`.
    private static func whiteGlyph(from base: NSImage, in rect: NSRect) -> NSImage {
        let pixelsWide = Int(rect.width * 2)
        let pixelsHigh = Int(rect.height * 2)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        rep.size = rect.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        base.draw(in: NSRect(origin: .zero, size: rect.size))
        NSColor.white.set()
        NSRect(origin: .zero, size: rect.size).fill(using: .sourceAtop)
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: rect.size)
        image.addRepresentation(rep)
        return image
    }

    // MARK: - Helpers

    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Actions

    @objc private func switchText() {
        textSwitcher.switchSelectedText()
    }

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController { [weak self] in
                guard let self else { return }
                self.hotkeyManager.unregister()
                self.hotkeyManager.register()
                self.setupMenuBar()

                if self.hotkeyManager.registrationFailed {
                    let alert = NSAlert()
                    alert.messageText = "Не удалось зарегистрировать сочетание клавиш"
                    alert.informativeText = """
                        Возможно, это сочетание уже используется другим приложением \
                        или системой. Выберите другое сочетание.
                        """
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
        preferencesWindow?.showWindow(nil)
        activateApp()
    }

    @objc private func showAbout() {
        if aboutWindow == nil {
            aboutWindow = AboutWindowController()
        }
        aboutWindow?.showWindow(nil)
        activateApp()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
