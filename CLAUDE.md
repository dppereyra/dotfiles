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
    │   ├── .claude/          (agents/, skills/, keybindings.json, statusline-command.sh)
    │   └── .config/
    │       ├── alacritty/ astronvim/ bat/ fish/ kak/ mopidy/ neofetch/ qutebrowser/
    │       ├── resticprofile/ systemd/ zellij/
    │       ├── opencode/      (opencode.jsonc, plugins/ — no agents; opencode uses its built-ins)
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

## AI tooling config (`.claude/`, `.config/opencode/`)

`~/.claude` and `~/.config/opencode` are the one place where folding is **wanted**. Both hold live
runtime state — sessions, `history.jsonl`, `projects/`, `node_modules/` — so neither may ever become
a directory symlink. Because both already exist as real directories, Stow descends and links only
the six leaves, which is correct here:

| Target | Kind |
|---|---|
| `~/.claude/agents` | dir symlink |
| `~/.claude/skills` | dir symlink |
| `~/.claude/keybindings.json` | file symlink |
| `~/.claude/statusline-command.sh` | file symlink |
| `~/.config/opencode/opencode.jsonc` | file symlink |
| `~/.config/opencode/plugins` | dir symlink |

`bootstrap.sh` lists these six in `STOWED_TARGETS` alongside the `~/.config/*` dirs, so its
pre-flight check catches them too.

**Not tracked, on purpose:**
- `~/.claude/settings.json` — hardcodes absolute `/Applications/Dorothy.app/...` hook paths that
  won't exist on another machine.
- `~/.claude/mcp.json` — may carry credentials.
- Runtime state: `sessions/`, `projects/`, `history.jsonl`, `backups/`, `shell-snapshots/`,
  `cache/`, `ide/`, `node_modules/`.
- `.history/` anywhere — VS Code Local History extension artefacts. Ignored by both
  `station/global_gitignore` and this repo's own `.gitignore`.

**opencode has no agents.** `opencode agent list` returns only its 7 built-ins (`build`, `plan`,
`explore`, `general`, `compaction`, `summary`, `title`); there are no user-defined ones to track. If
any are added later they belong in `src/configs/.config/opencode/agent/`. Note their frontmatter is
*not* interchangeable with Claude's: opencode expects `mode:` and a `provider/model` model string,
where Claude Code uses a bare `sonnet`. Copying files between the two directories will not work.

Once symlinked, `~/.claude/skills` serves both tools — opencode reads that path too.

### Temporary: agents are copies, not symlinks

Until the migration below completes, `src/configs/.claude/agents/` is a **copy** of
`~/.claude/agents/` and the two will drift as agents are edited. Refresh with:

```bash
rsync -a --delete --exclude='.history' ~/.claude/agents/ src/configs/.claude/agents/
```

After stowing, this stops mattering — they become the same files, and an agent created from a
Claude Code `/agents` session writes straight into the repo working tree and shows up in
`git status`. That is intended, if surprising the first time.

## Migration status

The Stow layout is **not yet applied on the primary machine**. `~/.gitconfig`, `~/.zshrc` and all 11
`~/.config/*` package dirs are still real files, `~/.config/station` and `~/.config/scripts` don't
exist, `~/station` and `~/.station` are both still present, and `~/.gitconfig` still points
`excludesfile` at the pre-migration `~/station/global_gitignore`. Running `./bootstrap.sh` today
exits 1 at the conflict check, before touching anything — clearing those targets is the remaining
work.

## `scripts/` vs `src/scripts/`

Two different things, both plural "scripts", easy to confuse:
- **`scripts/`** (root) — one-shot tool installers (`install-<tool>.sh`). Not stowed. Meant to be run standalone in ephemeral cloud dev environments as well as by `bootstrap.sh`.
- **`src/scripts/`** — everyday shell utilities (not installers), stowed to `~/.config/scripts` and put on `PATH` by `station/runcom/s04_paths.zsh`.

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow` on macOS)

## Real secrets

`station/runcom/s97_work_config.sample.zsh` and `s98_secrets.sample.zsh` are templates. The real, filled-in `s97_work_config.zsh` / `s98_secrets.zsh` are intentionally untracked (gitignored via `station/global_gitignore`) — never commit real values there.
