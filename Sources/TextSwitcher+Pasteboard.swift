import AppKit

extension TextSwitcher {

    /// Snapshot every type+data pair on the pasteboard so we can re-create the
    /// items later. Reads happen synchronously on the caller's queue.
    static func snapshot(of pasteboard: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        return pasteboard.pasteboardItems?.map { item -> [NSPasteboard.PasteboardType: Data] in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict
        } ?? []
    }

    /// Re-populate the pasteboard with the previously snapshotted items.
    /// An empty `items` array is a valid saved state — it means the original
    /// pasteboard was empty, and "restoring" must put it back into that
    /// state (clear it), not no-op and leave intermediate Cmd+C content
    /// behind.
    static func restoreClipboard(
        _ items: [[NSPasteboard.PasteboardType: Data]],
        to pasteboard: NSPasteboard
    ) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }
        let pasteboardItems = items.map { dict -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in dict {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(pasteboardItems)
    }

    /// Wait on the main queue (without blocking it) for `pasteboard.changeCount`
    /// to differ from `initialChangeCount`, or for `timeout` to elapse.
    /// `completion` is always called exactly once, on the main queue, with
    /// `true` if the clipboard changed and `false` on timeout.
    static func pollForClipboardChange(
        initialChangeCount: Int,
        timeout: TimeInterval,
        pollInterval: TimeInterval,
        pasteboard: NSPasteboard,
        completion: @escaping (Bool) -> Void
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        func poll() {
            if pasteboard.changeCount != initialChangeCount {
                completion(true)
                return
            }
            if Date() >= deadline {
                completion(false)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval, execute: poll)
        }
        poll()
    }
}
