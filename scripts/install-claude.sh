#!/usr/bin/env bash
set -euo pipefail

# Installs the Claude Code CLI. On macOS this is the `claude-code` cask
# (not the `claude` cask, which is the unrelated desktop app).
#
# npm's default global prefix is often a root-owned /usr, so `npm install -g`
# dies with EACCES for an unprivileged user and takes bootstrap.sh down with it.
# Install into the station prefix instead — install-paths.sh creates it and
# station/runcom/s04_paths.zsh already puts its bin dir on PATH as $NPM_BIN.
NPM_PREFIX="$HOME/.config/station/npm"
export PATH="$NPM_PREFIX/bin:$HOME/.local/bin:$PATH"

if command -v claude &>/dev/null; then
  echo "claude already installed ($(claude --version 2>/dev/null || echo unknown))"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install --cask claude-code
elif command -v npm &>/dev/null; then
  mkdir -p "$NPM_PREFIX"
  npm install -g --prefix "$NPM_PREFIX" @anthropic-ai/claude-code
else
  echo "Neither Homebrew nor npm available — install Claude Code manually: https://claude.com/product/claude-code" >&2
  exit 1
fi

echo "claude installed: $(claude --version 2>/dev/null || echo unknown)"
