#!/usr/bin/env bash
set -euo pipefail

if command -v asdf &>/dev/null; then
  echo "asdf already installed ($(asdf version))"
  exit 0
fi

echo "Installing asdf..."

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install asdf

elif [[ "$(uname -s)" == "Linux" ]]; then
  version=$(curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest \
              | grep '"tag_name"' | cut -d'"' -f4)
  arch=$(uname -m)
  [[ "$arch" == "x86_64" ]]  && arch="amd64"
  [[ "$arch" == "aarch64" ]] && arch="arm64"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL \
    "https://github.com/asdf-vm/asdf/releases/download/${version}/asdf-${version}-linux-${arch}.tar.gz" \
    | tar -xz -C "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/asdf"

else
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
fi

echo "asdf installed: $(asdf version)"
