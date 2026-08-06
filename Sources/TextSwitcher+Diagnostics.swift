import Foundation

extension TextSwitcher {

    /// Path to a plain-text diagnostic log appended on every conversion.
    /// Off by default — the log contains the user's selected text and the
    /// converted result. Enable per session for triage with:
    ///   defaults write com.komandakycto.bilingual-switcher BILINGUAL_DIAG -bool YES
    static let diagLogPath = "/tmp/bilingual-switcher.log"
    static let diagEnabledKey = "BILINGUAL_DIAG"

    static func diag(_ message: String) {
        guard UserDefaults.standard.bool(forKey: diagEnabledKey) else { return }
        let line = "\(Self.diagTimestamp()) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        let url = URL(fileURLWithPath: diagLogPath)
        if FileManager.default.fileExists(atPath: diagLogPath) {
            if let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
                return
            }
        }
        try? data.write(to: url)
    }

    private static let diagFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private static func diagTimestamp() -> String {
        diagFormatter.string(from: Date())
    }
}
