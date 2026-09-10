#!/usr/bin/env bash
# Shared stow logic for bootstrap.sh (personal machine) and install.sh
# (DevPod / ephemeral containers). Sourced, not executed.

# Full target paths, because not everything stowed lives directly under ~/.config —
# ~/.claude/*, ~/.config/opencode/*, ~/.copilot/*, ~/.codex/*, and ~/.gemini/config/* are
# leaves inside directories that must stay real (they hold live tool session state).
STOWED_TARGETS=(
  "$HOME/.config/alacritty"
  "$HOME/.config/astronvim"
  "$HOME/.config/bat"
  "$HOME/.config/fish"
  "$HOME/.config/kak"
  "$HOME/.config/mopidy"
  "$HOME/.config/neofetch"
  "$HOME/.config/qutebrowser"
  "$HOME/.config/resticprofile"
  "$HOME/.config/systemd"
  "$HOME/.config/zellij"
  "$HOME/.config/station"
  "$HOME/.claude/agents"
  "$HOME/.claude/skills"
  "$HOME/.claude/keybindings.json"
  "$HOME/.claude/statusline-command.sh"
  "$HOME/.config/opencode/opencode.jsonc"
  "$HOME/.config/opencode/plugins"
  "$HOME/.config/opencode/agents"
  "$HOME/.copilot/agents"
  "$HOME/.codex/agents"
  "$HOME/.gemini/config/agents"
)

# Directories that must exist as REAL directories before stowing, so that stow
# links only the leaves listed above instead of folding the whole directory into
# a single symlink. On a personal machine these already exist because the tools
# have been run; in a fresh container they do not, so they must be created first.
REAL_PARENT_DIRS=(
  "$HOME/.claude"
  "$HOME/.config/opencode"
  "$HOME/.copilot"
  "$HOME/.codex"
  "$HOME/.gemini/config"
)

dotfiles::ensure_real_parents() {
  local dir
  for dir in "${REAL_PARENT_DIRS[@]}"; do
    if [[ -L "$dir" ]]; then
      echo "  ! $dir is a symlink but must be a real directory — it holds live tool state." >&2
      return 1
    fi
    mkdir -p "$dir"
  done
}

# Reports (exit 1) any stow target that already exists as a real, non-symlink path.
dotfiles::find_conflicts() {
  local target conflict_found=0
  for target in "${STOWED_TARGETS[@]}"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "  ! $target already exists as a real file or directory — stow will fold into per-file symlinks instead of one clean symlink."
      conflict_found=1
    fi
  done
  return "$conflict_found"
}

# The scripts package used to be stowed with --target=$HOME/.config, which
# links the package's *contents* into that directory: ~/.config/clean-all-py,
# ~/.config/download-common-images and ~/.config/git. Two things were wrong with
# that. STATION_SCRIPTS in runcom/s04_paths.zsh puts ~/.config/scripts on PATH,
# and that directory never existed; and ~/.config/git is git's own XDG config
# directory, so the hooks package was landing on top of it. Targeting
# $HOME/.config/scripts puts each script where PATH expects it and leaves
# ~/.config/git alone. This removes the symlinks the old layout left behind.
dotfiles::remove_stale_script_links() {
  local dotfiles_dir="$1" entry name link
  for entry in "$dotfiles_dir"/src/scripts/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    link="$HOME/.config/$name"
    [[ -L "$link" ]] || continue
    # Only ever remove a symlink that resolves into this repo's src/scripts.
    if [[ "$(readlink -f "$link")" == "$(readlink -f "$entry")" ]]; then
      echo "  ~ removing stale link from the old scripts layout: $link"
      rm -f -- "$link"
    fi
  done
}

dotfiles::stow_all() {
  local dotfiles_dir="$1"
  echo "== Stowing dotfiles =="
  mkdir -p "$HOME/.config"
  stow --restow --target="$HOME" --dir="$dotfiles_dir/src" configs

  echo "== Stowing shell utility scripts (-> ~/.config/scripts) =="
  dotfiles::remove_stale_script_links "$dotfiles_dir"
  mkdir -p "$HOME/.config/scripts"
  stow --restow --target="$HOME/.config/scripts" --dir="$dotfiles_dir/src" scripts
}
