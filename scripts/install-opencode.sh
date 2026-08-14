#!/usr/bin/env bash
set -euo pipefail

if command -v opencode &>/dev/null; then
  echo "opencode already installed ($(opencode --version 2>/dev/null || echo unknown))"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install opencode
elif command -v npm &>/dev/null; then
  npm install -g opencode-ai
else
  echo "Neither Homebrew nor npm available — install opencode manually: https://opencode.ai" >&2
  exit 1
fi

echo "opencode installed: $(opencode --version 2>/dev/null || echo unknown)"
