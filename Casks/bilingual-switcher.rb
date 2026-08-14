cask "bilingual-switcher" do
  version "1.4"
  sha256 "3a8471609755b093eaf0e4ec951886a262d7dd1bd4b418726a11de16baaed00b"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.4/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
