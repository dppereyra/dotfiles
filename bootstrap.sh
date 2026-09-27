#!/usr/bin/env bash
#
# Personal-machine entrypoint. For ephemeral environments (DevPod, Codespaces,
# Gitpod/Ona) use install.sh instead — it installs its own prerequisites and
# backs conflicting files out of the way rather than stopping.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/stow.sh
source "$DOTFILES_DIR/scripts/lib/stow.sh"

if ! command -v stow &>/dev/null; then
  echo "GNU Stow is required. Install it first (e.g. 'brew install stow' or your distro's package)." >&2
  exit 1
fi

echo "== Checking for pre-existing real (non-symlink) stow targets =="
if ! dotfiles::find_conflicts; then
  echo
  echo "Review the paths above, back up/remove anything that's not still needed, then re-run bootstrap.sh."
  echo "Note: ~/.claude, ~/.config/opencode, ~/.copilot, ~/.codex, and ~/.gemini/config themselves"
  echo "must stay REAL directories — they hold runtime state. Only the leaves listed above are stowed."
  exit 1
fi

dotfiles::ensure_real_parents
dotfiles::stow_all "$DOTFILES_DIR"

# These two live OUTSIDE the repo on purpose. ~/.config/station is a symlink into
# this working tree, so anything under it is one `git add -f` away from a public
# repo. Keys and client identity must never sit there. Created empty; populate by
# hand per machine.
echo "== Creating machine-local directories (not tracked) =="
mkdir -p "$HOME/.config/secrets"   # GPG/age keys, restic password file, PEMs
mkdir -p "$HOME/.config/work"      # work/client gitconfig fragments
echo "  ~/.config/secrets and ~/.config/work ready"

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
  install-gh.sh
  install-az.sh
  install-worktrunk.sh
  install-neovim.sh
  install-neovim-deps.sh
  install-git-town.sh      # after neovim-deps: that is what gives goenv a Go
  install-tmux-plugins.sh
)
for installer in "${INSTALLERS[@]}"; do
  echo "-- $installer --"
  "$DOTFILES_DIR/scripts/$installer"
done

cat <<'EOF'

== Bootstrap complete. Remaining manual steps: ==
  * Open tmux and press 'prefix + I' to install the plugins TPM now knows about.
  * Open nvim once so lazy.nvim installs the plugins, then ':MasonToolsInstall'
    for the language servers and ':checkhealth' to confirm. Re-run
    'scripts/install-neovim-deps.sh --check' to see what is still missing, or
    '--all' for the optional language toolchains (zig, lldb) and the
    toggleterm integrations (lazydocker, k9s, mc). Go is no longer in '--all':
    a default run installs it through goenv, since install-goenv.sh only clones
    the manager and leaves it with no toolchain.
  * Install fzf (not automated — e.g. 'brew install fzf').
  * Copy the *.sample.zsh templates in ~/.config/station/runcom/ to their
    real names (s97_work_config.zsh, s98_secrets.zsh) and fill in real
    values — these stay untracked, same as before.
  * Install a Nerd Font for the catppuccin tmux/prompt theming (terminal-app setting, not CLI-installable).
See README.md for details.
EOF
