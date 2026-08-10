cask "bilingual-switcher" do
  version "1.3"
  sha256 "fa3983639db5fe278dcb5be96b28572a84d8e6650c8d1a06be7dd6e87fbde99a"

  url "https://github.com/gluck-59/bilingual-switcher/releases/download/v1.3/BilingualSwitcher.zip"
  name "Bilingual Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/bilingual-switcher"

  app "BilingualSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.komandakycto.bilingual-switcher.plist",
  ]
end
