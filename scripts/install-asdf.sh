#!/usr/bin/env bash
set -euo pipefail

# Installs the asdf binary directly at ~/.local/bin (already on PATH via
# station/runcom/s04_paths.zsh) instead of piping a remote install script
# through bash, and instead of the old git-clone shim-based install that
# used to live at ~/station/asdf pinned to v0.14.0.

if command -v asdf &>/dev/null; then
  echo "asdf already installed ($(asdf version))"
  exit 0
fi

mkdir -p "$HOME/.local/bin"

version=$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
[[ "$arch" == "x86_64" ]] && arch="amd64"
[[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"

echo "Installing asdf ${version} (${os}-${arch}) to ~/.local/bin ..."
curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/${version}/asdf-${version}-${os}-${arch}.tar.gz" \
  | tar -xz -C "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/asdf"

echo "asdf installed: $("$HOME/.local/bin/asdf" version)"
