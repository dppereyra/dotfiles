# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Previously managed via a bare git repo at `~/.station` (alias `mystation`); now migrated to this repo for portability and devcontainer compatibility.

## Directory Structure

```
dotfiles/
├── CLAUDE.md
├── install.sh          (install/bootstrap script — to be implemented)
├── src/
│   ├── configs/        (stow package — mirrors $HOME)
│   │   └── .config/
│   │       ├── alacritty/
│   │       ├── astronvim/
│   │       ├── bat/
│   │       ├── fish/
│   │       ├── kak/
│   │       ├── mopidy/
│   │       ├── neofetch/
│   │       ├── qutebrowser/
│   │       ├── resticprofile/
│   │       ├── systemd/
│   │       └── zellij/
│   └── scripts/        (standalone scripts — to be implemented)
```

## How to Apply

From the repo root, run:

```bash
stow --target=$HOME --dir=src configs
```

This creates symlinks from `~/.config/*` → `dotfiles/src/configs/.config/*`.

To simulate without making changes (dry run):

```bash
stow --target=$HOME --dir=src --simulate configs
```

To remove symlinks:

```bash
stow --target=$HOME --dir=src --delete configs
```

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow` on macOS)

## install.sh

The `install.sh` script is a placeholder and will eventually automate the full bootstrap process (installing dependencies, running stow, etc.).
