#!/usr/bin/env bash
#
# Installs neovim and clones the config from gitlab.com/dppereyra/nvim-conf.
# The external tooling that config shells out to lives in install-neovim-deps.sh.
#
# The config needs neovim 0.10 or newer: lua/core/plugin-manager.lua calls
# vim.uv, and lua/core/config-health.lua asserts 0.10-dev or newer. Distro
# packages disagree about whether they can supply that:
#
#   Arch-based   pacman   current (rolling), use the package
#   Fedora       dnf      current, use the package
#   Debian       apt      way too old (bookworm ships 0.7.2)
#   Ubuntu       apt      too old (24.04 ships 0.9.5, and it is pinned there)
#   macOS        brew     current, use the formula
#
# So: install from the package manager where that is known to work, then verify
# the version we actually got and fall back to the official static tarball when
# it is too old. That covers Debian/Ubuntu, and also the enterprise rebuilds
# where dnf's neovim comes from EPEL and lags.
#
# The tarball lands in $STATION_SDK/neovim with a symlink in $STATION_BIN,
# which station/runcom/s04_paths.zsh puts on PATH ahead of /usr/bin — so a
# too-old distro nvim can stay installed, it just stops being the one found.
#
# Pin a version with NVIM_VERSION (e.g. NVIM_VERSION=v0.11.2); the default is
# whatever GitHub currently calls the latest release.

set -euo pipefail

NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=10

STATION_HOME="$HOME/.config/station"
STATION_BIN="$STATION_HOME/bin"
NVIM_SDK="$STATION_HOME/sdk/neovim"

export PATH="$STATION_BIN:$PATH"

NVIM_CONFIG="$HOME/.config/nvim"
NVIM_CONF_SSH="git@gitlab.com:dppereyra/nvim-conf.git"
NVIM_CONF_HTTPS="https://gitlab.com/dppereyra/nvim-conf.git"

log()  { printf -- '-- %s\n' "$*"; }
note() { printf -- '  ~ %s\n' "$*"; }
warn() { printf -- '  ! %s\n' "$*" >&2; }

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    warn "need root for: $*"
    return 1
  fi
}

# `nvim --version` opens with e.g. "NVIM v0.9.5" or "NVIM v0.12.0-dev+1234".
nvim_version_ok() {
  command -v nvim &>/dev/null || return 1

  local raw major minor
  raw="$(nvim --version 2>/dev/null | head -1 | sed -n 's/^NVIM v\([0-9]\+\.[0-9]\+\).*/\1/p')"
  [[ -n "$raw" ]] || return 1

  major="${raw%%.*}"
  minor="${raw##*.}"
  if (( major > NVIM_MIN_MAJOR )); then
    return 0
  elif (( major == NVIM_MIN_MAJOR && minor >= NVIM_MIN_MINOR )); then
    return 0
  fi
  return 1
}

install_from_package_manager() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
      # An old nvim on macOS is a stale formula, not a pinned one.
      if brew list neovim &>/dev/null; then
        log "Upgrading neovim from Homebrew"
        brew upgrade neovim
      else
        log "Installing neovim from Homebrew"
        brew install neovim
      fi
      return 0
    fi
    warn "no Homebrew on this Mac — install it, or neovim by hand"
    return 1
  fi

  if command -v pacman &>/dev/null; then
    log "Installing neovim from pacman (Arch-based, ships current)"
    as_root pacman -Sy --needed --noconfirm neovim
  elif command -v dnf &>/dev/null; then
    log "Installing neovim from dnf"
    as_root dnf install -y neovim
  elif command -v apt-get &>/dev/null; then
    # Deliberately skipped: no apt suite carries 0.10+ for the releases this
    # repo targets, so installing it only to replace it wastes a download.
    note "skipping apt's neovim (too old for this config), going straight to the official build"
    return 1
  else
    note "no known package manager, using the official build"
    return 1
  fi
}

install_from_tarball() {
  local base assets asset tmpdir extracted downloaded=""

  case "$(uname -m)" in
    x86_64|amd64)
      # nvim-linux64.tar.gz was renamed to nvim-linux-x86_64.tar.gz in 0.10.4;
      # keep the old name as a fallback for a pinned older NVIM_VERSION.
      assets=(nvim-linux-x86_64.tar.gz nvim-linux64.tar.gz)
      ;;
    aarch64|arm64)
      assets=(nvim-linux-arm64.tar.gz)
      ;;
    *)
      warn "no official neovim build for $(uname -m) — build from source: https://github.com/neovim/neovim/blob/master/BUILD.md"
      return 1
      ;;
  esac

  if [[ -n "${NVIM_VERSION:-}" ]]; then
    base="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION"
  else
    base="https://github.com/neovim/neovim/releases/latest/download"
  fi

  tmpdir="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand tmpdir now, while it is still set
  trap "rm -rf '$tmpdir'" RETURN

  for asset in "${assets[@]}"; do
    log "Downloading $base/$asset"
    if curl -fsSL --retry 2 -o "$tmpdir/nvim.tar.gz" "$base/$asset"; then
      downloaded="$asset"
      break
    fi
    note "$asset not available for this release"
  done

  if [[ -z "$downloaded" ]]; then
    warn "could not download a neovim build from $base"
    return 1
  fi

  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"
  extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d -name 'nvim-*' -print -quit)"
  if [[ -z "$extracted" || ! -x "$extracted/bin/nvim" ]]; then
    warn "unexpected archive layout in $downloaded"
    return 1
  fi

  # Replace only after a good download, so a failed run leaves the previous
  # install in place.
  mkdir -p "$(dirname "$NVIM_SDK")" "$STATION_BIN"
  rm -rf "$NVIM_SDK"
  mv "$extracted" "$NVIM_SDK"
  ln -sfn "$NVIM_SDK/bin/nvim" "$STATION_BIN/nvim"

  hash -r 2>/dev/null || true
  note "installed to $NVIM_SDK, linked as $STATION_BIN/nvim"

  # A distro nvim left in place is harmless in a login shell, where
  # s04_paths.zsh puts $STATION_BIN first, but it is what a bare
  # /usr/bin/env or a non-login shell still finds — so say it out loud.
  local other
  for other in /usr/local/bin/nvim /usr/bin/nvim; do
    if [[ -e "$other" && "$(readlink -f "$other")" != "$(readlink -f "$STATION_BIN/nvim")" ]]; then
      note "$other is still installed ($("$other" --version 2>/dev/null | head -1))"
      note "$STATION_BIN comes first on PATH in a login shell, so the new build wins there"
      break
    fi
  done
}

if nvim_version_ok; then
  log "neovim already new enough: $(nvim --version | head -1) ($(command -v nvim))"
else
  if command -v nvim &>/dev/null; then
    note "$(nvim --version | head -1) is older than the ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} this config needs"
  fi

  # Returns 0 only when it actually installed something, so that the "still too
  # old" note below is about a package we just pulled, not one we declined.
  if install_from_package_manager; then
    if nvim_version_ok; then
      log "neovim from the package manager is new enough: $(nvim --version | head -1)"
    else
      note "the package manager's neovim is still too old, falling back to the official build"
      install_from_tarball
    fi
  else
    install_from_tarball
  fi

  if ! nvim_version_ok; then
    warn "neovim is still older than ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} — the config will not load"
    warn "see https://github.com/neovim/neovim/blob/master/INSTALL.md"
    exit 1
  fi
fi

if [[ -d "$NVIM_CONFIG/.git" ]]; then
  log "nvim config already present at $NVIM_CONFIG"
else
  # An SSH clone hangs on a host-key prompt wherever there is no key loaded,
  # which is every ephemeral container. Only take that path when SSH to GitLab
  # actually authenticates; otherwise fall back to HTTPS.
  log "Cloning nvim config ..."
  if GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
     ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@gitlab.com 2>&1 \
     | grep -q "Welcome to GitLab"; then
    git clone "$NVIM_CONF_SSH" "$NVIM_CONFIG"
  else
    note "no usable SSH key for gitlab.com, cloning over HTTPS"
    git clone "$NVIM_CONF_HTTPS" "$NVIM_CONFIG"
  fi
fi

log "neovim installed: $(nvim --version | head -1)"
note "run install-neovim-deps.sh for the external tooling the config needs"
