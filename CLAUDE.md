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
- **qutebrowser runtime state.** `~/.config/qutebrowser` is a symlink into this tree, so a
  browser writes into the repo as you use it. Only the hand-maintained config is tracked
  (`config.py`, `autoconfig.yml`, `quickmarks`, `bookmarks/`); `.gitignore` blocks cookies,
  `history.sqlite*`, `sessions/`, `webengine/`, `cmd-history`, `greasemonkey/` and any stray
  `*.sqlite`/`*.db`/`*.log`, since those carry session tokens and browsing history. Note that
  `quickmarks` and `bookmarks/urls` **are** tracked — don't bookmark a URL with a token in it.

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

### Agents are generated — edit `src/agents/`, never `src/configs/*/agents/`

All five `agents/` directories under `src/configs/` are **build output**. The source of truth is
`src/agents/`, and `scripts/build-agents.py` renders every tool's format from it:

```bash
python3 scripts/build-agents.py            # rewrite all five tool trees
python3 scripts/build-agents.py --check    # verify committed output is current (exit 1 if stale)
```

- `src/agents/<name>.md` — one file per agent: frontmatter (`role`, `color`, `delegates`,
  `description`) and the agent's own prose, with `{{STANDARDS}}` and `{{CLOSING}}` markers where
  the shared blocks go.
- `src/agents/_standards/` — the shared blocks, written once: per-`role` operating standards and
  reporting format (`implementer`, `reviewer`) plus the Trello `card-write-back.md` protocol.

An agent inherits the block for its `role` unless it defines that section inline itself. The four
advisory agents (`mgr-product-owner`, `mgr-recruiter`, `ops-architect`, `ops-automation`) carry
their own standards and reporting inline because those are genuinely role-specific, and the
generator leaves them alone.

Do **not** rsync the live `~/...` directories back into `src/configs/` — that would overwrite
generated files with hand-edits and silently break the single-source model. Edit `src/agents/`,
regenerate, then copy out (or stow, once the migration below completes).

### Agents are live via Stow — no copy step

All five live `~/...` agent directories are now symlinks into this repo, so
`scripts/build-agents.py` writes straight through to what the tools actually read. There is no
refresh step, and the copy-drift that used to leave the tracked trees weeks behind the live ones
is now structurally impossible.

## Migration status

The Stow layout **is applied on the primary machine**. All 22 entries in `bootstrap.sh`'s
`STOWED_TARGETS` are symlinks into this repo, `~/.config/station` exists, and `excludesfile`
points at `~/.config/station/global_gitignore`. Only the two `stow` calls were run — the
installer phase of `bootstrap.sh` was not, since the toolchain was moved across rather than
rebuilt.

**`~/.station` (the bare repo) is gone.** Nothing referenced it: the `mystation` aliases were
removed from `s08_aliases.zsh` and the `includeIf gitdir:~/.station` block from `.gitconfig`.
`$HOME` is no longer a git work-tree.

### Machine-local directories outside the repo

Two directories deliberately live **outside** this repo, created empty by `bootstrap.sh` and
populated by hand per machine. `~/.config/station` is a symlink into this working tree, so
anything under it is one `git add -f` away from a public repo — keys and client identity must
never sit there.

| Path | Holds |
|---|---|
| `~/.config/secrets` | GPG/age keys, `restic_repo_secret`, PEMs. `RESTIC_PASSWORD_FILE` in `s98_secrets.zsh` points here. |
| `~/.config/work` | `work.gitconfig`, `work_gitignore`, and client fragments. `.gitconfig`'s `includeIf gitdir:~/projects/work/` points at `~/.config/work/work.gitconfig`. |

Remaining cleanup:
- `~/station` is down to under 600KB and what is left is deliberate, not pending: `containers/`
  (its own git repo, and its compose files hold plaintext secrets — move it to `~/projects/`
  rather than delete), `scripts/setup/` (superseded by `scripts/install-*.sh`), and copies of
  what already moved to `~/.config/secrets` and `~/.config/work`.
- `s97_work_config.zsh` and `s98_secrets.zsh` are **auto-created from the `.sample.zsh`
  templates** by `s03_variables.zsh` when missing. That means a fresh machine gets empty
  placeholders, not the real values — copy the real files across by hand, or CLI tools that
  read those env vars will silently break.
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
- **`src/scripts/`** — the Stow *package*; everyday shell utilities (not installers), stowed to `~/.config/scripts` and put on `PATH` by `station/runcom/s04_paths.zsh`.

The package deliberately nests one level — the files live in **`src/scripts/scripts/`**, not
`src/scripts/`. Stow links a package's *contents* into the target, so a flat `src/scripts/` would
scatter `clean-all-py`, `download-common-images` and `git/` loose into `~/.config/`. Nesting makes
the package contain a `scripts/` directory, which is what produces the single `~/.config/scripts`
symlink. Add new utilities to `src/scripts/scripts/`.

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
