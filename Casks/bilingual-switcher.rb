cask "bilingual-switcher" do
  version "1.5"
  sha256 "e9f04e28d44f0f515285e6af1f569df932d7350f5e9398954e492a909e8a5424"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.5/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gluck59.bilingual-switcher.plist",
  ]
end
