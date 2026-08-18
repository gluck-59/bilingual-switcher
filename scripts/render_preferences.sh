#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT_DIR="${TMPDIR:-/tmp}/yrswitcher-preview"
mkdir -p "$OUT_DIR"
ibtool --compile "$OUT_DIR/PreferencesWindow.nib" Resources/PreferencesWindow.xib
swiftc -module-name YRSwitcher -o "$OUT_DIR/render" \
  Sources/PreferencesWindow.swift \
  Sources/ClosableWindow.swift \
  Sources/HotkeyManager.swift \
  Sources/ModifierOnlyHotkeyMonitor.swift \
  Sources/ModifierTapDetector.swift \
  scripts/render_preferences_main.swift
"$OUT_DIR/render" "${1:-preview.png}"