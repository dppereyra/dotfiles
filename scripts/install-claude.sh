#!/usr/bin/env bash
set -euo pipefail

# Installs the Claude Code CLI. On macOS this is the `claude-code` cask
# (not the `claude` cask, which is the unrelated desktop app).

if command -v claude &>/dev/null; then
  echo "claude already installed ($(claude --version 2>/dev/null || echo unknown))"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install --cask claude-code
elif command -v npm &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
else
  echo "Neither Homebrew nor npm available — install Claude Code manually: https://claude.com/product/claude-code" >&2
  exit 1
fi

echo "claude installed: $(claude --version 2>/dev/null || echo unknown)"
