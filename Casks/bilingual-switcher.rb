cask "bilingual-switcher" do
  version "1.0.1"
  sha256 "9c0c8f77d80cdb067d4d3c31017dfbada3cd134d63454abc6c370de0b2c20f67"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.0.1/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
