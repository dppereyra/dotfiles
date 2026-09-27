#!/usr/bin/env bash
set -euo pipefail

# Installs git-town, which the [alias] block in .gitconfig delegates to
# (`git hack`, `git sync`, `git propose`, `git ship`, ...). Without it every one
# of those aliases fails with "git: 'town' is not a git command".
#
# On Linux this goes through `go install` rather than the GitHub release
# assets: the Go module proxy is reachable from far more sandboxes than GitHub
# release downloads are, and GOTOOLCHAIN=auto (Go's default) fetches whatever
# newer Go the module asks for through that same proxy. The binary lands in
# ~/.local/bin, which station/runcom/s04_paths.zsh already has on PATH.

# On a personal machine Go comes from goenv (install-neovim-deps.sh installs it),
# whose shims zsh only gets from `goenv init -`, which does not run here.
GOENV_ROOT="${GOENV_ROOT:-$HOME/.config/station/envs/goenv}"
export PATH="$HOME/.local/bin:$GOENV_ROOT/shims:$PATH"

if command -v git-town &>/dev/null; then
  echo "git-town already installed ($(git-town --version 2>/dev/null || echo unknown))"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install git-town
  exit 0
fi

# Not `command -v go`: a goenv shim resolves even with no Go version selected,
# and only fails when run.
if ! go version &>/dev/null; then
  echo "go not available — install Go (scripts/install-goenv.sh, then install-neovim-deps.sh) or git-town manually: https://www.git-town.com/install" >&2
  exit 1
fi

# The module path carries the major version (…/git-town/v22), so `@latest` on a
# fixed path never crosses a major release. Walk the proxy upward from a known
# floor to find the newest major instead of hard-coding one that goes stale.
proxy="$(go env GOPROXY)"
proxy="${proxy%%[,|]*}"
[[ -z "$proxy" || "$proxy" == direct || "$proxy" == off ]] && proxy=https://proxy.golang.org

major=22
while curl -fsS -m 15 -o /dev/null "$proxy/github.com/git-town/git-town/v$((major + 1))/@latest"; do
  major=$((major + 1))
done

module="github.com/git-town/git-town/v$major"
echo "Installing $module@latest into ~/.local/bin ..."
mkdir -p "$HOME/.local/bin"
GOBIN="$HOME/.local/bin" go install "$module@latest"

echo "git-town installed: $(git-town --version 2>/dev/null || echo unknown)"
