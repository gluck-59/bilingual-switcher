cask "bilingual-switcher" do
  version "1.1.0"
  sha256 "78254c808c33a907d19895453528544c6d0697e71ac1a88d737a0631ec4fed7d"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.1.0/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
