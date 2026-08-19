#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v stow &>/dev/null; then
  echo "GNU Stow is required. Install it first (e.g. 'brew install stow' or your distro's package)." >&2
  exit 1
fi

echo "== Checking for pre-existing real (non-symlink) stow targets =="
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
conflict_found=0
for target in "${STOWED_TARGETS[@]}"; do
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  ! $target already exists as a real file or directory — stow will fold into per-file symlinks instead of one clean symlink."
    conflict_found=1
  fi
done
if [[ "$conflict_found" -eq 1 ]]; then
  echo
  echo "Review the paths above, back up/remove anything that's not still needed, then re-run bootstrap.sh."
  echo "Note: ~/.claude, ~/.config/opencode, ~/.copilot, ~/.codex, and ~/.gemini/config themselves"
  echo "must stay REAL directories — they hold runtime state. Only the leaves listed above are stowed."
  exit 1
fi

echo "== Stowing dotfiles =="
stow --target="$HOME" --dir="$DOTFILES_DIR/src" configs

echo "== Stowing shell utility scripts (-> ~/.config/scripts) =="
stow --target="$HOME/.config" --dir="$DOTFILES_DIR/src" scripts

echo "== Running tool installers =="
INSTALLERS=(
  install-paths.sh
  install-zinit.sh
  install-asdf.sh
  install-pyenv.sh
  install-goenv.sh
  install-nodenv.sh
  install-rbenv.sh
  install-phpenv.sh
  install-opencode.sh
  install-claude.sh
  install-neovim.sh
  install-tmux-plugins.sh
)
for installer in "${INSTALLERS[@]}"; do
  echo "-- $installer --"
  "$DOTFILES_DIR/scripts/$installer"
done

cat <<'EOF'

== Bootstrap complete. Remaining manual steps: ==
  * Open tmux and press 'prefix + I' to install the plugins TPM now knows about.
  * Install fzf and fd (not automated — e.g. 'brew install fzf fd').
  * Copy the *.sample.zsh templates in ~/.config/station/runcom/ to their
    real names (s97_work_config.zsh, s98_secrets.zsh) and fill in real
    values — these stay untracked, same as before.
  * Install a Nerd Font for the catppuccin tmux/prompt theming (terminal-app setting, not CLI-installable).
See README.md for details.
EOF
