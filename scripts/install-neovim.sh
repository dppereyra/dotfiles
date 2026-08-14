#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvim &>/dev/null; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    brew install neovim
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y neovim
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm neovim
  else
    echo "No known package manager found — install neovim manually: https://github.com/neovim/neovim/blob/master/INSTALL.md" >&2
    exit 1
  fi
fi

NVIM_CONFIG="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG/.git" ]]; then
  echo "nvim config already present at $NVIM_CONFIG"
else
  echo "Cloning nvim config ..."
  git clone git@gitlab.com:dppereyra/nvim-conf.git "$NVIM_CONFIG"
fi

echo "neovim installed: $(nvim --version | head -1)"
