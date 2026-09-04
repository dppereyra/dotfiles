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
    │   ├── .copilot/          (agents/ — GitHub Copilot custom agents, *.agent.md)
    │   ├── .codex/            (agents/ — OpenAI Codex custom agents, *.toml)
    │   ├── .gemini/
    │   │   └── config/
    │   │       └── agents/    (Google Antigravity custom subagents, *.md)
    │   └── .config/
    │       ├── alacritty/ astronvim/ bat/ fish/ kak/ mopidy/ neofetch/ qutebrowser/
    │       ├── resticprofile/ systemd/ zellij/
    │       ├── opencode/      (opencode.jsonc, plugins/, agents/)
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

## AI tooling config (`.claude/`, `.config/opencode/`, `.copilot/`, `.codex/`, `.gemini/config/`)

`~/.claude`, `~/.config/opencode`, `~/.copilot`, `~/.codex`, and `~/.gemini/config` are the places
where folding is **wanted**. All five hold live runtime state — sessions, auth tokens,
`history.jsonl`, `projects/`, `node_modules/` — so none of them may ever become a directory
symlink. Because all five already exist as real directories, Stow descends and links only the
specific leaves below, which is correct here:

| Target | Kind |
|---|---|
| `~/.claude/agents` | dir symlink |
| `~/.claude/skills` | dir symlink |
| `~/.claude/keybindings.json` | file symlink |
| `~/.claude/statusline-command.sh` | file symlink |
| `~/.config/opencode/opencode.jsonc` | file symlink |
| `~/.config/opencode/plugins` | dir symlink |
| `~/.config/opencode/agents` | dir symlink |
| `~/.copilot/agents` | dir symlink |
| `~/.codex/agents` | dir symlink |
| `~/.gemini/config/agents` | dir symlink |

`bootstrap.sh` lists all ten in `STOWED_TARGETS` alongside the `~/.config/*` dirs, so its
pre-flight check catches them too.

**Not tracked, on purpose:**
- `~/.claude/settings.json` — hardcodes absolute `/Applications/Dorothy.app/...` hook paths that
  won't exist on another machine.
- `~/.claude/mcp.json` — may carry credentials.
- `~/.codex/config.toml` — carries machine-specific MCP server paths (also pointing at
  `/Applications/Dorothy.app/...`) alongside the `[agents]` block that enables Codex's
  multi-agent tools (`enabled = true`, `max_concurrent_threads_per_session`,
  `default_subagent_reasoning_effort`). Only `~/.codex/agents/` is tracked; add the `[agents]`
  block to `config.toml` by hand on each machine, same as Claude's `settings.json`.
- Runtime state: `sessions/`, `projects/`, `history.jsonl`, `backups/`, `shell-snapshots/`,
  `cache/`, `ide/`, `node_modules/`, `auth.json`, `oauth_creds.json`, `*.sqlite*`,
  `command-history-state.json`, `session-state/`.
- `.history/` anywhere — VS Code Local History extension artefacts. Ignored by both
  `station/global_gitignore` and this repo's own `.gitignore`.

**All five tools now run the same agent fleet.** It's built around `mgr-product-owner` (the one
agent meant to be talked to directly) coordinating a Trello-card pipeline — owning leads,
`qa-conftest`/`qa-playwright`/`qa-robot-framework` writing test cases, an interchangeable
`qa-reviewer-1/2/3` pool, `ops-security` as a mandatory cross-cutting gate on every card, and
`mgr-recruiter` to create new specialist agents when a card needs tooling the fleet doesn't
cover yet. The Scope/Standards/Delegation/Reporting prose is shared almost verbatim across all
five directories; only the frontmatter shape differs per tool's own convention:

| Tool | Frontmatter shape | Notes |
|---|---|---|
| Claude Code | `name`, `description`, `model: sonnet`, `color` | canonical source; edit here first |
| opencode | `description`, `mode` (`primary` for `mgr-product-owner`, else `subagent`), `color` | filename *is* the agent name — no `name:` field. Current convention is plural `agents/`; singular `agent/` still works but is legacy. |
| GitHub Copilot | `name`, `description`, `tools`, `agents` (delegation allowlist), `user-invocable`, `disable-model-invocation` | file suffix is `*.agent.md`, not `*.md`. The `agents:` allowlist is derived from each source file's own `## Delegation` table. |
| OpenAI Codex | `name`, `description`, `developer_instructions`, `sandbox_mode` | TOML, not Markdown+YAML. Requires the `[agents]` block in `config.toml` (see above, not tracked). |
| Google Antigravity | `name`, `description`, `subagent`, `mainAgent` (`true` only for `mgr-product-owner`), `model`, `commandExecutionPolicy` | body is prefixed with an `# System Prompt` H1, per Antigravity's convention. |

None of these frontmatter shapes are interchangeable — copying a file directly between two of
these directories without translating the frontmatter will not work.

Once symlinked, `~/.claude/skills` serves both Claude Code and opencode — opencode reads that
path too.

### Temporary: agents are copies, not symlinks

Until the migration below completes, every `agents/` directory under `src/configs/` is a **copy**
of its live `~/...` counterpart, and each pair will drift as agents are edited. Refresh with:

```bash
rsync -a --delete --exclude='.history' ~/.claude/agents/          src/configs/.claude/agents/
rsync -a --delete                      ~/.config/opencode/agents/ src/configs/.config/opencode/agents/
rsync -a --delete                      ~/.copilot/agents/         src/configs/.copilot/agents/
rsync -a --delete                      ~/.codex/agents/           src/configs/.codex/agents/
rsync -a --delete                      ~/.gemini/config/agents/   src/configs/.gemini/config/agents/
```

Claude Code is the canonical source for the fleet's content — edit agents there, then re-derive
the other four (frontmatter differs enough per tool that this isn't a plain copy; see the table
above). After stowing, the copy-drift problem stops mattering for Claude Code and opencode: they
become the same files, and an agent created from a Claude Code `/agents` session writes straight
into the repo working tree and shows up in `git status`. Copilot, Codex, and Antigravity don't
have an equivalent in-session agent-creation flow to worry about yet.

## Migration status

The Stow layout **is applied on the primary machine**. All 22 entries in `bootstrap.sh`'s
`STOWED_TARGETS` are symlinks into this repo, the conflict check passes, and `./bootstrap.sh`
runs to completion (exit 0). `~/.station` is gone and `excludesfile` points at
`~/.config/station/global_gitignore`.

Remaining cleanup:
- `~/station` still exists as a real directory; its content now lives at `~/.config/station`.
  Verify nothing unique is left there, then remove it.
- Because `~/.config/station` is a symlink *into this repo*, everything the installers put under
  `$STATION_HOME` (`envs/`, `npm/`, `zinit/`, `sdk/`, …) lands in this working tree. Those paths
  are gitignored, but they mean the repo carries several hundred MB of installed toolchain that
  `git status` no longer shows. Keep the ignore list in `.gitignore` in sync with
  `scripts/install-paths.sh`.
- Tools that append to stowed files write into the repo: `gh auth login` adds a `[credential]`
  block to `src/configs/.gitconfig`, and opencode's own installer appends a `PATH` line to
  `src/configs/.zshrc`. Both show up as unexpected `git status` modifications after running
  those tools — decide per-machine whether to keep them.

## `scripts/` vs `src/scripts/`

Two different things, both plural "scripts", easy to confuse:
- **`scripts/`** (root) — one-shot tool installers (`install-<tool>.sh`). Not stowed. Meant to be run standalone in ephemeral cloud dev environments as well as by `bootstrap.sh`.
- **`src/scripts/`** — everyday shell utilities (not installers), stowed to `~/.config/scripts` and put on `PATH` by `station/runcom/s04_paths.zsh`.

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow` on macOS)

## Real secrets

`station/runcom/s97_work_config.sample.zsh` and `s98_secrets.sample.zsh` are templates. The real,
filled-in `s97_work_config.zsh` / `s98_secrets.zsh` are intentionally untracked — never commit real
values there.

What keeps them out is **this repo's own `.gitignore`**, which lists both paths explicitly. That is
the right mechanism: because `~/.config/station` is a symlink into `src/configs/.config/station`,
those files genuinely live in this working tree, so ignoring them is this repo's job.

`station/global_gitignore` is *not* what protects them, despite what this file used to say. It is
the global `core.excludesfile`, and its purpose is to keep personal artefacts out of **other**
repos — work and client projects — not to manage this one's contents. Don't add these paths there.
