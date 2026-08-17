cask "yr-switcher" do
  version "2.0"
  sha256 "6edd35ef6d5d3cd8d725d7e4e275fb9b24b5639b7c8a3e46991d1b09876ab4e1"

  url "https://github.com/gluck-59/yr-switcher/releases/download/v2.0/YRSwitcher.zip"
  name "ЯR Switcher"
  desc "Convert selected text between keyboard layouts with a hotkey"
  homepage "https://github.com/gluck-59/yr-switcher"

  app "YRSwitcher.app"

  zap trash: [
    "~/Library/Preferences/com.gluck59.bilingual-switcher.plist",
  ]
end
