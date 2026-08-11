cask "bilingual-switcher" do
  version "1.3"
  sha256 "e8a291546001e0fc8ef016521c5017a2a51708a39dc513a4e933451dfe74a5ff"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.3/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
