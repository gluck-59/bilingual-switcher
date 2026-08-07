cask "bilingual-switcher" do
  version "1.0.2"
  sha256 "4ee1a2ad0b58093358e0a061607b216c4f0809a072810d388843e0279eac19a3"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.0.2/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
