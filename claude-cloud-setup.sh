#!/usr/bin/env bash
#
# Entrypoint for Claude Code on the web (claude.ai/code) cloud environments.
#
# The environment's "Setup script" field runs as root in a fresh Ubuntu
# container before Claude starts. Paste this there — it keeps the real logic in
# this repo, so changing the environment is a commit rather than a settings edit:
#
#   #!/bin/bash
#   DOTFILES_DIR="$HOME/.dotfiles"
#   if [ -d "$DOTFILES_DIR/.git" ]; then
#     git -C "$DOTFILES_DIR" pull --ff-only --quiet || true
#   else
#     git clone --depth 1 https://github.com/dppereyra/dotfiles "$DOTFILES_DIR" || exit 0
#   fi
#   "$DOTFILES_DIR/claude-cloud-setup.sh" || true
#
# Why this is not install.sh, the DevPod/Codespaces entrypoint:
#   * The cloud container is not a blank image. ~/.gitconfig is written by the
#     session itself (commit identity, SSH signing, proxy settings) and stowing
#     ours over it — install.sh would back it up and replace it — breaks every
#     commit. Our git settings go in ~/.config/git/config instead, via an
#     include, which git reads *before* ~/.gitconfig, so the session's values
#     still win wherever the two overlap.
#   * ~/.claude/skills already exists and holds skills the platform ships, so
#     it cannot become a directory symlink. Each of our skills is linked into it
#     individually instead; ~/.claude/agents does not exist and is linked whole.
#   * There is no interactive terminal. zsh, zinit, tmux, the prompt theme and
#     the editor are dead weight here; Claude runs commands through bash. What
#     is worth having is the CLI tooling Claude itself calls and the agent fleet.
#   * The image already ships git, curl, jq, rg, node/npm, python3/uv, go and
#     cargo/rustup, so none of that is (re)installed.
#
# Every step reports and carries on: a setup script that fails can cost the
# whole session, and one unreachable package host should not.
#
# Tunables (set them in the environment's variables, or inline before the call):
#   CLOUD_INSTALLERS    scripts/install-*.sh to run, space separated
#   CLOUD_APT_PACKAGES  extra distro packages
#
# Credentials are NOT handled here and must never be committed. Set them as
# environment variables on the cloud environment instead:
#   GH_TOKEN                                     gh reads it directly, no login step
#   AZURE_CLIENT_ID / AZURE_TENANT_ID / AZURE_CLIENT_SECRET
#                                                for `az login --service-principal`

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

DEFAULT_INSTALLERS="install-gh.sh install-az.sh install-worktrunk.sh install-git-town.sh"
INSTALLERS_TO_RUN="${CLOUD_INSTALLERS:-$DEFAULT_INSTALLERS}"

# git-delta is core.pager in .gitconfig and git-lfs backs its [filter "lfs"].
# xz-utils unpacks worktrunk's release archive, and the linter is there for
# this repo's own shell scripts. fd-find and tree are cheap and get used.
APT_PACKAGES="git-delta git-lfs shellcheck xz-utils fd-find tree ${CLOUD_APT_PACKAGES:-}"

BASHRC_MARKER="# >>> dotfiles: claude-cloud-setup.sh >>>"
BASHRC_END="# <<< dotfiles: claude-cloud-setup.sh <<<"

log()  { printf '== %s\n' "$*"; }
note() { printf '  ~ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }

failed=()

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    sudo "$@"
  else
    warn "need root for: $* (no passwordless sudo available)"
    return 1
  fi
}

install_apt_packages() {
  command -v apt-get &>/dev/null || { note "no apt-get; skipping distro packages"; return 0; }

  local pkg missing=()
  for pkg in $APT_PACKAGES; do
    dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
  done
  if [[ "${#missing[@]}" -eq 0 ]]; then
    note "distro packages already present"
    return 0
  fi

  log "Installing distro packages: ${missing[*]}"
  as_root apt-get update -qq || return 1
  if as_root apt-get install -y --no-install-recommends "${missing[@]}"; then
    return 0
  fi

  # One unknown or unreachable package fails the whole transaction; retry one
  # at a time so the rest still land, and report just the ones that did not.
  local rc=0
  for pkg in "${missing[@]}"; do
    as_root apt-get install -y --no-install-recommends "$pkg" &>/dev/null \
      || { warn "could not install $pkg"; rc=1; }
  done
  return "$rc"
}

# Debian/Ubuntu ship fd as `fdfind` to avoid a name clash; everything else
# (and every habit) calls it `fd`.
link_fd() {
  command -v fd &>/dev/null && return 0
  command -v fdfind &>/dev/null || return 0
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  note "linked fdfind -> ~/.local/bin/fd"
}

run_installers() {
  local installer script
  for installer in $INSTALLERS_TO_RUN; do
    script="$DOTFILES_DIR/scripts/$installer"
    echo "-- $installer --"
    if [[ ! -x "$script" ]]; then
      warn "no such installer: $installer"
      failed+=("$installer")
      continue
    fi
    "$script" || { warn "$installer failed"; failed+=("$installer"); }
  done
}

# Links $2 -> $1 only when $2 is absent or already a symlink. A real file or
# directory there belongs to someone else, and is left alone.
link_path() {
  local source="$1" target="$2"
  if [[ -e "$target" && ! -L "$target" ]]; then
    warn "$target exists and is not a symlink; leaving it alone"
    return 1
  fi
  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
  note "$target -> $source"
}

link_claude_config() {
  local src="$DOTFILES_DIR/src/configs/.claude" skill rc=0

  log "Linking the agent fleet and skills into ~/.claude"
  mkdir -p "$HOME/.claude/skills"
  link_path "$src/agents" "$HOME/.claude/agents" || rc=1

  for skill in "$src"/skills/*/; do
    [[ -d "$skill" ]] || continue
    skill="${skill%/}"
    link_path "$skill" "$HOME/.claude/skills/$(basename "$skill")" || rc=1
  done
  return "$rc"
}

configure_git() {
  local xdg="${XDG_CONFIG_HOME:-$HOME/.config}"

  log "Layering the tracked .gitconfig under the session's own ~/.gitconfig"
  # .gitconfig points core.excludesfile at ~/.config/station/global_gitignore.
  link_path "$DOTFILES_DIR/src/configs/.config/station" "$xdg/station" || true

  mkdir -p "$xdg/git"
  git config --file "$xdg/git/config" --replace-all include.path "$DOTFILES_DIR/src/configs/.gitconfig"
  note "$xdg/git/config includes $DOTFILES_DIR/src/configs/.gitconfig"

  if command -v git-lfs &>/dev/null; then
    git lfs install --skip-repo &>/dev/null || true
  fi
}

# Only what Claude's own bash benefits from. worktrunk's shell function is what
# lets `wt switch` actually change directory; without it wt can only print the
# path. Rewritten between markers on every run, so re-running never duplicates.
configure_bash() {
  local bashrc="$HOME/.bashrc" tmp
  touch "$bashrc"
  tmp="$(mktemp)"
  sed "/^$BASHRC_MARKER\$/,/^$BASHRC_END\$/d" "$bashrc" > "$tmp"
  cat >> "$tmp" <<EOF
$BASHRC_MARKER
command -v wt >/dev/null 2>&1 && eval "\$(wt config shell init bash 2>/dev/null)"
$BASHRC_END
EOF
  cat "$tmp" > "$bashrc"
  rm -f "$tmp"
  note "worktrunk shell integration added to $bashrc"
}

report() {
  echo
  log "Tool versions"
  local tool
  for tool in gh az wt git-town delta git-lfs shellcheck fd; do
    if command -v "$tool" &>/dev/null; then
      printf '  ok      %-10s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '  MISSING %-10s\n' "$tool"
    fi
  done
}

log "Claude cloud setup from $DOTFILES_DIR"

install_apt_packages || failed+=("apt packages")
link_fd
run_installers
link_claude_config   || failed+=("claude config links")
configure_git        || failed+=("git config")
configure_bash       || failed+=("bashrc")
report

if [[ "${#failed[@]}" -gt 0 ]]; then
  echo
  log "Setup finished with failures: ${failed[*]}"
  echo "Re-run a single installer with: $DOTFILES_DIR/scripts/<name>"
else
  log "Setup complete"
fi

# Always 0: see the header. The report above is where failures show.
exit 0
