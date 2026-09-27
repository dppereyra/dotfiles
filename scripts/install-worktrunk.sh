#!/usr/bin/env bash
set -euo pipefail

# Installs worktrunk (`wt`), the git worktree manager. The zsh side is already
# wired: station/runcom/s09_completions.zsh runs `wt config shell init zsh`
# whenever `wt` is on PATH, which is what lets `wt switch` change directory.
#
# Order of preference on Linux:
#   1. The prebuilt static (musl) binary from the GitHub release — seconds, and
#      no toolchain needed.
#   2. `cargo install` from crates.io, for when GitHub release downloads are
#      blocked. worktrunk tracks a recent rustc (its rust-version moves up
#      often), so an older toolchain is updated through rustup and retried
#      rather than falling back to an old worktrunk.
#
# Pin a version with WORKTRUNK_VERSION (e.g. WORKTRUNK_VERSION=v0.80.0).

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if command -v wt &>/dev/null && wt --version &>/dev/null; then
  echo "worktrunk already installed ($(wt --version))"
  exit 0
fi

install_prebuilt() {
  local target base tmpdir binary
  case "$(uname -m)" in
    x86_64|amd64)  target=x86_64-unknown-linux-musl ;;
    aarch64|arm64) target=aarch64-unknown-linux-musl ;;
    *) return 1 ;;
  esac
  command -v xz &>/dev/null || return 1

  if [[ -n "${WORKTRUNK_VERSION:-}" ]]; then
    base="https://github.com/max-sixty/worktrunk/releases/download/$WORKTRUNK_VERSION"
  else
    base="https://github.com/max-sixty/worktrunk/releases/latest/download"
  fi

  tmpdir="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand tmpdir now, while it is still set
  trap "rm -rf '$tmpdir'" RETURN

  echo "Downloading $base/worktrunk-$target.tar.xz ..."
  curl -fsSL -m 120 --retry 2 -o "$tmpdir/wt.tar.xz" "$base/worktrunk-$target.tar.xz" || return 1
  tar -xJf "$tmpdir/wt.tar.xz" -C "$tmpdir"

  # cargo-dist nests the binaries one directory down; find them rather than
  # hard-coding that layout.
  binary="$(find "$tmpdir" -type f -name wt -perm -u+x -print -quit)"
  [[ -n "$binary" ]] || return 1

  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$binary" "$HOME/.local/bin/wt"
  if [[ -f "$(dirname "$binary")/git-wt" ]]; then
    install -m 0755 "$(dirname "$binary")/git-wt" "$HOME/.local/bin/git-wt"
  fi
}

install_with_cargo() {
  command -v cargo &>/dev/null || {
    echo "cargo not available — install Rust (https://rustup.rs) or worktrunk manually: https://github.com/max-sixty/worktrunk" >&2
    return 1
  }

  local version_args=()
  [[ -n "${WORKTRUNK_VERSION:-}" ]] && version_args=(--version "${WORKTRUNK_VERSION#v}")

  if cargo install --locked "${version_args[@]}" worktrunk; then
    return 0
  fi

  # The usual failure is "requires rustc 1.NN or newer". Update stable and try
  # once more; anything else will fail the same way again and say why.
  if command -v rustup &>/dev/null; then
    echo "  ~ retrying with an up-to-date stable toolchain"
    rustup update stable --no-self-update
    cargo +stable install --locked "${version_args[@]}" worktrunk
  else
    return 1
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install max-sixty/worktrunk/wt
elif ! install_prebuilt; then
  echo "  ~ prebuilt worktrunk release unavailable, building from crates.io"
  install_with_cargo
fi

hash -r 2>/dev/null || true
echo "worktrunk installed: $(wt --version)"
echo "  ~ zsh integration comes from s09_completions.zsh; for bash: eval \"\$(wt config shell init bash)\""
