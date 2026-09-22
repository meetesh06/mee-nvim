#!/bin/bash

set -e

cd "$(dirname "$0")"
BIN="$HOME/.local/bin"; mkdir -p "$BIN"
have() { command -v "$1" >/dev/null; }
SUDO=$([ "$(id -u)" -eq 0 ] || echo sudo)

# nvim >= 0.12 is required (vim.pack). Install it yourself: https://github.com/neovim/neovim/releases
nvim --headless +'lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)' +qa 2>/dev/null \
  || { echo "install nvim >= 0.12 first"; exit 1; }

# search: rg, fd, fzf | C/C++: clangd, clang-format | JS: node (vtsls, prettierd)
if have brew; then
  brew install ripgrep fd fzf llvm node tree-sitter-cli
elif have apt-get; then
  $SUDO apt-get update -qq
  $SUDO apt-get install -y git curl build-essential unzip ripgrep fd-find fzf clangd clang-format
  have node || $SUDO apt-get install -y nodejs npm
  have fd || ln -sf "$(command -v fdfind)" "$BIN/fd"   # Debian names it fdfind
fi
npm_g() { if [ -w "$(npm prefix -g)" ]; then npm i -g "$@"; else $SUDO npm i -g "$@"; fi; }
npm_g @vtsls/language-server @fsouza/prettierd

# fzf-lua wants fzf >= 0.53; Ubuntu 24.04 ships 0.44, so fetch the release binary.
fzf_new() { have fzf && [ "$(printf '0.53\n%s\n' "$(fzf --version | cut -d' ' -f1)" | sort -V | head -1)" = 0.53 ]; }
if ! fzf_new && [ "$(uname)" = Linux ]; then
  v=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/junegunn/fzf/releases/latest | sed 's|.*/v||')
  a=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v$v/fzf-$v-linux_$a.tar.gz" | tar -xz -C "$BIN" fzf
fi

# clangd: distro builds lag (Ubuntu 24.04 = 18) and misreport errors against newer
# standard library headers; use the official release, like Mason did. x86_64 only.
if [ "$(uname)" = Linux ] && [ "$(uname -m)" = x86_64 ] && [ ! -e "$BIN/clangd" ]; then
  v=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/clangd/clangd/releases/latest | sed 's|.*/||')
  tmp=$(mktemp -d); dest="$HOME/.local/share"
  curl -fsSL -o "$tmp/c.zip" "https://github.com/clangd/clangd/releases/download/$v/clangd-linux-$v.zip"
  unzip -qo "$tmp/c.zip" -d "$dest" && rm -rf "$tmp"
  ln -sf "$dest/clangd_$v/bin/clangd" "$BIN/clangd"   # keeps its lib/clang headers alongside
fi

# tree-sitter CLI (compiles parsers). Distro packages are too old; use the release binary.
if ! have tree-sitter && [ "$(uname)" = Linux ]; then
  arch=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/')
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$arch.gz" \
    | gunzip > "$BIN/tree-sitter" && chmod +x "$BIN/tree-sitter"
fi

# Plugins install on first start; do it now so the first real launch is quick.
nvim --headless +qa
# Terminal colours matching the editor (enable with `theme = deepblue` in ghostty's config)
[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty" ] && nvim -l scripts/gen-theme.lua --install
echo "done. Open nvim and run :checkhealth if anything looks off."
