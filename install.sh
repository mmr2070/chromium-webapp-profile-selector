#!/bin/bash
# install.sh — Chromium Webapp Profile Selector installer

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
SYS_DESKTOP="/usr/share/applications/chromium.desktop"

echo "Installing Chromium Webapp Profile Selector..."

# 1. Install scripts
mkdir -p "$BIN_DIR"
install -m 755 "$REPO_DIR/chromium-webapp-wrapper"       "$BIN_DIR/chromium-webapp-wrapper"
install -m 755 "$REPO_DIR/webapp-profile-selector-tui"   "$BIN_DIR/webapp-profile-selector-tui"
install -m 755 "$REPO_DIR/webapp-profile-reset"           "$BIN_DIR/webapp-profile-reset"

# 2. Verify PATH includes ~/.local/bin
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
  echo "WARNING: $BIN_DIR is not in your PATH. You may need to add it."
fi

# 3. Build desktop override
if [[ ! -f "$SYS_DESKTOP" ]]; then
  echo "ERROR: System Chromium desktop entry not found at $SYS_DESKTOP"
  echo "  Is Chromium installed?"
  exit 1
fi

mkdir -p "$DESKTOP_DIR"
cp -p "$SYS_DESKTOP" "$DESKTOP_DIR/chromium.desktop"

tmp_file=$(mktemp)
awk '
/^Exec=/ {
    sub(/^Exec=(\/usr\/bin\/)?chromium/, "Exec=chromium-webapp-wrapper")
    print
    next
}
{ print }
' "$DESKTOP_DIR/chromium.desktop" > "$tmp_file"
mv "$tmp_file" "$DESKTOP_DIR/chromium.desktop"

# 4. Refresh desktop database
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo "Installation complete."
echo ""
echo "Run 'webapp-profile-reset --status' to verify."
