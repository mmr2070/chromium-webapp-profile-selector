#!/bin/bash
# uninstall.sh — Chromium Webapp Profile Selector uninstaller

BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

echo "Uninstalling Chromium Webapp Profile Selector..."

# 1. Remove scripts
rm -f "$BIN_DIR/chromium-webapp-wrapper"
rm -f "$BIN_DIR/webapp-profile-selector-tui"
rm -f "$BIN_DIR/webapp-profile-reset"

# 2. Remove desktop override (restores system entry as fallback)
rm -f "$DESKTOP_DIR/chromium.desktop"

# 3. Refresh desktop database
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "Uninstall complete."
echo ""
echo "NOTE: Your webapp profile mappings in ~/.config/webapp-profile-selector/"
echo "were NOT deleted. Remove them manually if desired:"
echo "  rm -rf ~/.config/webapp-profile-selector/"
echo ""
echo "Chromium profiles and browsing data were NOT modified."
