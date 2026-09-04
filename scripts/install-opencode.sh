#!/usr/bin/env bash
set -euo pipefail

# npm's default global prefix is often a root-owned /usr, so `npm install -g`
# dies with EACCES for an unprivileged user and takes bootstrap.sh down with it.
# Install into the station prefix instead — install-paths.sh creates it and
# station/runcom/s04_paths.zsh already puts its bin dir on PATH as $NPM_BIN.
NPM_PREFIX="$HOME/.config/station/npm"
export PATH="$NPM_PREFIX/bin:$PATH"

if command -v opencode &>/dev/null; then
  echo "opencode already installed ($(opencode --version 2>/dev/null || echo unknown))"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install opencode
elif command -v npm &>/dev/null; then
  mkdir -p "$NPM_PREFIX"
  npm install -g --prefix "$NPM_PREFIX" opencode-ai
else
  echo "Neither Homebrew nor npm available — install opencode manually: https://opencode.ai" >&2
  exit 1
fi

echo "opencode installed: $(opencode --version 2>/dev/null || echo unknown)"
