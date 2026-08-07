import Carbon

enum InputSourceSwitcher {

    /// Activate the given target layout after conversion.
    static func switchTo(target: LayoutInfo) {
        TISSelectInputSource(target.source)
    }
}
