# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Previously managed via a bare git repo at `~/.station` (alias `mystation`); migrated to this repo for portability and devcontainer compatibility. `~/station`'s content now lives at `~/.config/station`.

## Directory Structure

```
dotfiles/
├── CLAUDE.md
├── README.md
├── LICENSE                (root only — outside src/, so Stow never touches it)
├── .stowrc                 (sets --dir=src as the default for manual `stow` invocations from the repo root)
├── bootstrap.sh            (personal-machine entrypoint: stow both packages, run scripts/install-*.sh)
├── scripts/                (root-level tool installers, install-<tool>.sh — NOT stowed;
│                             usable standalone by Codespaces/DevPod/Ona, or via bootstrap.sh)
└── src/
    ├── configs/             (stow package #1 — target $HOME)
    │   ├── .gitconfig .gitmux.conf .ansible.cfg .p10k.zsh .tmux.conf .wezterm.lua .Xresources .zshrc
    │   ├── .ssh/{config,conf.d,keys.d,work.d}
    │   └── .config/
    │       ├── alacritty/ astronvim/ bat/ fish/ kak/ mopidy/ neofetch/ qutebrowser/
    │       ├── resticprofile/ systemd/ zellij/
    │       └── station/       (runcom/, gitconfig fragments, global_gitignore, restic_ignore)
    └── scripts/              (stow package #2 — target $HOME/.config, becomes one symlink ~/.config/scripts)
```

## How to Apply

From the repo root, run the full bootstrap (stows both packages, then runs every tool installer):

```bash
./bootstrap.sh
```

Or stow only, without installing tools (a `.stowrc` at the repo root sets `--dir=src` by default):

```bash
stow --target=$HOME configs
stow --target=$HOME/.config scripts
```

To simulate without making changes (dry run), add `--simulate`. To remove symlinks, use `--delete` instead of the default action.

**Note:** Stow only produces a clean directory-level symlink (e.g. `~/.config/nvim` → the whole package subtree) when the target doesn't already exist as a real directory. If `~/.config/<tool>` already exists as real files, Stow "folds" and symlinks individual files inside instead — `bootstrap.sh` checks for this and refuses to proceed until conflicting real directories are cleared.

## `scripts/` vs `src/scripts/`

Two different things, both plural "scripts", easy to confuse:
- **`scripts/`** (root) — one-shot tool installers (`install-<tool>.sh`). Not stowed. Meant to be run standalone in ephemeral cloud dev environments as well as by `bootstrap.sh`.
- **`src/scripts/`** — everyday shell utilities (not installers), stowed to `~/.config/scripts` and put on `PATH` by `station/runcom/s04_paths.zsh`.

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow` on macOS)

## Real secrets

`station/runcom/s97_work_config.sample.zsh` and `s98_secrets.sample.zsh` are templates. The real, filled-in `s97_work_config.zsh` / `s98_secrets.zsh` are intentionally untracked (gitignored via `station/global_gitignore`) — never commit real values there.
