cask "bilingual-switcher" do
  version "1.2"
  sha256 "2095a73dee79b73b5a05b72e311ea6c8d8a872ca3a0099ecc9ffb5b6aa9f9208"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.2/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
