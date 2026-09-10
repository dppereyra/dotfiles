#!/usr/bin/env bash
#
# Entrypoint for ephemeral dev environments (DevPod, GitHub Codespaces, Gitpod/Ona).
#
# DevPod clones this repo to ~/dotfiles inside the container and runs the first
# script it finds from: install.sh, install, bootstrap.sh, bootstrap,
# script/bootstrap, setup.sh, setup. This file therefore takes precedence over
# bootstrap.sh, which stays the personal-machine entrypoint.
#
#   devpod up . --dotfiles https://github.com/dppereyra/dotfiles
#
# Differences from bootstrap.sh, all of them forced by the container context:
#   * Installs its own prerequisites (stow, zsh, git, curl) — a container image
#     is not guaranteed to have them, and exiting 1 fails the whole `devpod up`.
#   * Backs conflicting files out of the way instead of aborting. Base images
#     ship their own ~/.zshrc etc.; on a personal machine that collision means
#     "stop and look", in a disposable container it means "ours wins".
#   * Runs only the installers that work unattended. Anything needing an SSH
#     key or an interactive prompt is left out of the default set.
#
# Override the installer set with DOTFILES_INSTALLERS, e.g.
#   devpod up . --dotfiles <url> --dotfiles-script-env DOTFILES_INSTALLERS="install-paths.sh install-asdf.sh"

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/stow.sh
source "$DOTFILES_DIR/scripts/lib/stow.sh"

export DEBIAN_FRONTEND=noninteractive

# Installers that are safe unattended: no SSH keys, no prompts, no compilers.
# Deliberately excluded from the default set:
#   install-neovim.sh      - clones a private repo; needs a key or a token
#   install-neovim-deps.sh - installs system packages as root, and is pointless
#                            without the config install-neovim.sh clones
#   install-rbenv.sh       - compiles a C shim, slow and needs build deps
#   install-tmux-plugins.sh- TPM's actual plugin install is interactive
#   install-{py,go,node,php}env.sh - several minutes of clones for runtimes a
#                            given container usually does not need
DEFAULT_INSTALLERS="install-paths.sh install-zinit.sh install-opencode.sh install-claude.sh"
INSTALLERS_TO_RUN="${DOTFILES_INSTALLERS:-$DEFAULT_INSTALLERS}"

log() { printf '== %s\n' "$*"; }

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    sudo "$@"
  else
    echo "  ! need root for: $* (no passwordless sudo available)" >&2
    return 1
  fi
}

install_packages() {
  local pkgs=("$@")
  if command -v apt-get &>/dev/null; then
    as_root apt-get update -qq
    as_root apt-get install -y --no-install-recommends "${pkgs[@]}"
  elif command -v dnf &>/dev/null; then
    as_root dnf install -y "${pkgs[@]}"
  elif command -v apk &>/dev/null; then
    as_root apk add --no-cache "${pkgs[@]}"
  elif command -v pacman &>/dev/null; then
    as_root pacman -Sy --noconfirm "${pkgs[@]}"
  else
    echo "  ! no known package manager; install manually: ${pkgs[*]}" >&2
    return 1
  fi
}

ensure_prerequisites() {
  local missing=()
  command -v stow &>/dev/null || missing+=(stow)
  command -v git  &>/dev/null || missing+=(git)
  command -v curl &>/dev/null || missing+=(curl)
  command -v zsh  &>/dev/null || missing+=(zsh)

  if [[ "${#missing[@]}" -eq 0 ]]; then
    log "Prerequisites already present"
    return 0
  fi

  log "Installing prerequisites: ${missing[*]}"
  install_packages "${missing[@]}"
}

# Moves aside whatever stow reports as a conflict, then retries once. Never
# deletes: everything displaced lands next to itself as <name>.pre-dotfiles.
stow_package() {
  local target="$1" package="$2"
  local output attempt

  for attempt in 1 2; do
    if output="$(stow --restow --target="$target" --dir="$DOTFILES_DIR/src" "$package" 2>&1)"; then
      [[ -n "$output" ]] && printf '%s\n' "$output"
      return 0
    fi

    printf '%s\n' "$output"
    if [[ "$attempt" -eq 2 ]]; then
      echo "  ! stow still failing for '$package' after backing up conflicts" >&2
      return 1
    fi

    local conflicts backed_up=0
    conflicts="$(printf '%s\n' "$output" \
      | sed -n 's/^ *\* existing target is \(neither a link nor a directory\|not owned by stow\): //p' \
      | sort -u)"

    if [[ -z "$conflicts" ]]; then
      echo "  ! stow failed for '$package' for a reason other than file conflicts" >&2
      return 1
    fi

    local rel
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      local path="$target/$rel"
      [[ -e "$path" ]] || continue
      echo "  ~ backing up $path -> $path.pre-dotfiles"
      rm -rf -- "$path.pre-dotfiles"
      mv -- "$path" "$path.pre-dotfiles"
      backed_up=1
    done <<< "$conflicts"

    [[ "$backed_up" -eq 1 ]] || return 1
  done
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null || true)"
  [[ -n "$zsh_path" ]] || return 0

  # $SHELL is unreliable inside a container; read the passwd entry instead.
  local current
  current="$(getent passwd "$(id -un)" | cut -d: -f7)"
  [[ "$current" == "$zsh_path" ]] && { log "Login shell already $zsh_path"; return 0; }

  grep -qxF "$zsh_path" /etc/shells 2>/dev/null \
    || as_root sh -c "echo '$zsh_path' >> /etc/shells" 2>/dev/null || true

  if as_root chsh -s "$zsh_path" "$(id -un)" 2>/dev/null; then
    log "Login shell set to $zsh_path"
  else
    echo "  ~ could not change login shell to $zsh_path (non-fatal)" >&2
  fi
}

log "Installing dotfiles from $DOTFILES_DIR"
ensure_prerequisites

log "Creating directories that must stay real (they hold live tool state)"
dotfiles::ensure_real_parents

mkdir -p "$HOME/.config"
stow_package "$HOME" configs

dotfiles::remove_stale_script_links "$DOTFILES_DIR"
mkdir -p "$HOME/.config/scripts"
stow_package "$HOME/.config/scripts" scripts

log "Running installers: $INSTALLERS_TO_RUN"
failed=()
for installer in $INSTALLERS_TO_RUN; do
  script="$DOTFILES_DIR/scripts/$installer"
  if [[ ! -x "$script" ]]; then
    echo "  ! no such installer: $installer" >&2
    failed+=("$installer")
    continue
  fi
  echo "-- $installer --"
  # One broken installer must not fail the whole `devpod up`; report at the end.
  if ! "$script"; then
    echo "  ! $installer failed" >&2
    failed+=("$installer")
  fi
done

set_default_shell

if [[ "${#failed[@]}" -gt 0 ]]; then
  echo
  echo "== Dotfiles installed, but these installers failed: ${failed[*]} =="
  echo "Re-run individually with: $DOTFILES_DIR/scripts/<name>"
  exit 0
fi

log "Dotfiles installed"
