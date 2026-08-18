import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let controller = PreferencesWindowController(onHotkeyChanged: {})
controller.showWindow(nil)
controller.window?.makeKeyAndOrderFront(nil)
controller.window?.contentView?.layoutSubtreeIfNeeded()
controller.window?.displayIfNeeded()

guard let contentView = controller.window?.contentView else {
    fatalError("no content view")
}
let target = contentView.superview ?? contentView
let bounds = target.bounds
guard let rep = target.bitmapImageRepForCachingDisplay(in: bounds) else {
    fatalError("no bitmap rep")
}
target.cacheDisplay(in: bounds, to: rep)
guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("no png data")
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "preview.png"
try data.write(to: URL(fileURLWithPath: out))
print("rendered \(Int(bounds.width))x\(Int(bounds.height)) -> \(out)")
exit(0)