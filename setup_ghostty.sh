#!/bin/bash
# Install the ghostty config (extras/ghostty/config) and the deepblue theme.

set -e

cd "$(dirname "$0")"
THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes"
if [ "$(uname)" = Darwin ]; then
  CONF="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
else
  CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
fi

mkdir -p "$THEMES" "$(dirname "$CONF")"
cp extras/ghostty/deepblue "$THEMES/deepblue"

# Keep a backup of an existing config that differs from ours.
if [ -f "$CONF" ] && ! cmp -s extras/ghostty/config "$CONF"; then
  cp "$CONF" "$CONF.bak" && echo "backed up old config to $CONF.bak"
fi
cp extras/ghostty/config "$CONF"

# Monaspace font (Neon + Radon)
if [ "$(uname)" = Darwin ]; then
  compgen -G "$HOME/Library/Fonts/Monaspace*" >/dev/null || compgen -G "/Library/Fonts/Monaspace*" >/dev/null \
    || brew install --cask font-monaspace
elif ! fc-list 2>/dev/null | grep -qi monaspace; then
  echo "install the Monaspace font: https://github.com/githubnext/monaspace"
fi

echo "done. Reload ghostty's config with cmd+shift+, (ctrl+shift+, on Linux)."
