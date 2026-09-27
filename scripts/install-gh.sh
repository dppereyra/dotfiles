#!/usr/bin/env bash
set -euo pipefail

# Installs the GitHub CLI (gh).
#
# On apt systems this prefers GitHub's own apt repository, because the distro
# package lags badly (Ubuntu 24.04 ships 2.45). When cli.github.com is not
# reachable — a locked-down egress policy in a cloud sandbox, say — it falls
# back to the distro package rather than failing: an old gh beats no gh.

if command -v gh &>/dev/null; then
  echo "gh already installed ($(gh --version | head -1))"
  exit 0
fi

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    echo "  ! need root for: $*" >&2
    return 1
  fi
}

install_apt_official() {
  local keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
  local list=/etc/apt/sources.list.d/github-cli.list
  local tmp
  tmp="$(mktemp)"

  if ! curl -fsSL -m 30 -o "$tmp" https://cli.github.com/packages/githubcli-archive-keyring.gpg; then
    rm -f "$tmp"
    return 1
  fi

  as_root install -d -m 0755 /etc/apt/keyrings
  as_root install -m 0644 "$tmp" "$keyring"
  rm -f "$tmp"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
    | as_root tee "$list" >/dev/null

  # A repo that answered for the key but not for the index would break every
  # later apt-get update on the machine, so take it back out on failure.
  if ! as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq \
     || ! as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh; then
    as_root rm -f "$list" "$keyring"
    return 1
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install gh
elif command -v apt-get &>/dev/null; then
  if ! install_apt_official; then
    echo "  ~ cli.github.com unavailable, installing the distro gh package instead"
    as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh
  fi
elif command -v dnf &>/dev/null; then
  as_root dnf install -y gh
elif command -v pacman &>/dev/null; then
  as_root pacman -Sy --needed --noconfirm github-cli
elif command -v apk &>/dev/null; then
  as_root apk add --no-cache github-cli
else
  echo "No known package manager — install gh manually: https://cli.github.com" >&2
  exit 1
fi

echo "gh installed: $(gh --version | head -1)"
