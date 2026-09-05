# DPPereyra Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start

```bash
git clone git@github.com:dppereyra/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` will:
1. Confirm `stow` is installed.
2. Refuse to proceed if any stow target already exists as a real (non-symlink) file or directory — review and clear those first so Stow can create clean symlinks instead of folding into per-file ones.
3. `stow` both packages: `src/configs` → `$HOME`, `src/scripts` → `$HOME/.config` (so `~/.config/scripts` becomes one symlink).
4. Run every installer in `scripts/` (asdf, pyenv, goenv, nodenv, rbenv, phpenv, zinit, opencode, claude, neovim, tmux plugin manager).

Each installer in `scripts/` is also safe to run standalone — that's the intended path for ephemeral dev environments (GitHub Codespaces, DevPod, Ona/Gitpod): clone the repo and run just the installer(s) you need, e.g. `scripts/install-neovim.sh`, without going through the full personal-machine `bootstrap.sh`.

## What's not automated (manual steps)

- **tmux plugins**: `bootstrap.sh` clones TPM (tmux plugin manager) to `~/.tmux/plugins/tpm`, but the actual plugin install has to happen interactively — open tmux and press `prefix + I`.
- **fzf / fd**: referenced by the `tmux-fzf` / `tmux-fzf-url` plugins and general shell use, but not installed by any script here — install with your package manager, e.g. `brew install fzf fd`.
- **gitmux / lazygit**: referenced by `.tmux.conf`'s catppuccin status segments — install with your package manager if not already present.
- **Real secrets**: `~/.config/station/runcom/s97_work_config.sample.zsh` and `s98_secrets.sample.zsh` are templates. Copy them to `s97_work_config.zsh` / `s98_secrets.zsh` and fill in real values — both stay untracked (gitignored via `~/.config/station/global_gitignore`), never commit real values.
- **A Nerd Font**: needed for the catppuccin theming in tmux/p10k — this is a terminal-app setting, not something a script can install for you.

## Stow packages

A `.stowrc` at the repo root sets `--dir=src` by default, so run these from the repo root:

```bash
stow --target=$HOME configs          # dotfiles -> $HOME
stow --target=$HOME/.config scripts  # shell utility scripts -> ~/.config/scripts
```

Add `--simulate` to either command for a dry run, or replace the implicit stow action with `--delete` to remove the symlinks. (`bootstrap.sh` passes `--dir` explicitly instead of relying on `.stowrc`, since it doesn't depend on the caller's current directory.)

## AI tooling config

Config for five AI coding tools lives in the `configs` package: Claude Code (`.claude/`), opencode
(`.config/opencode/`), GitHub Copilot (`.copilot/`), OpenAI Codex (`.codex/`), and Google
Antigravity (`.gemini/config/`). All five of `~/.claude`, `~/.config/opencode`, `~/.copilot`,
`~/.codex`, and `~/.gemini/config` deliberately stay **real directories** — they hold session
state, auth tokens, and (for opencode) `node_modules` — so only specific leaves get symlinked:
`~/.claude/agents`, `~/.claude/skills`, `~/.claude/keybindings.json`,
`~/.claude/statusline-command.sh`, `~/.config/opencode/opencode.jsonc`,
`~/.config/opencode/plugins`, `~/.config/opencode/agents`, `~/.copilot/agents`,
`~/.codex/agents`, and `~/.gemini/config/agents`.

All five tools share the same underlying multi-agent fleet — a `mgr-product-owner`-led Trello
workflow with owning leads, QA authors/reviewers, and an `mgr-recruiter` that can create new
specialist agents — translated into each tool's own agent-definition format (Claude's `.md` with
`model`/`color` frontmatter, opencode's `.md` with `mode`/`permission`, Copilot's `*.agent.md` with
a `tools`/`agents` allowlist, Codex's `.toml` with `developer_instructions`, and Antigravity's `.md`
with an H1 `# System Prompt` body). The prose (Scope, Standards, Delegation, Reporting) is shared;
only the frontmatter shape differs per tool.

### Editing agents: one source, five renders

The five `agents/` directories under `src/configs/` are **generated output — never edit them by
hand.** The source of truth is:

- `src/agents/<name>.md` — one file per agent: frontmatter (`role`, `color`, `delegates`,
  `description`) plus the agent's own prose, with `{{STANDARDS}}` and `{{CLOSING}}` markers where
  the shared blocks belong.
- `src/agents/_standards/` — the blocks every agent shares, written once: the operating standards
  and reporting format for each `role` (`implementer`, `reviewer`), and the Trello
  `card-write-back.md` protocol used by all of them.

Edit a source file, then regenerate:

```bash
python3 scripts/build-agents.py            # rewrite all five tool trees
python3 scripts/build-agents.py --check    # verify output is current (exit 1 if stale)
```

An agent takes the shared block for its `role` unless it defines that section inline itself. The
four advisory agents (`mgr-product-owner`, `mgr-recruiter`, `ops-architect`, `ops-automation`)
carry their own standards and reporting inline, because those are genuinely role-specific rather
than duplicated.

This exists because the fleet was previously 330 hand-maintained files (66 agents × 5 tools) with
no generator: over half of each file was copy-pasted boilerplate, which had already drifted into
six competing variants and left the tracked copies weeks behind the live ones. Changing a shared
rule is now a one-file edit.

`~/.claude/settings.json` and `~/.claude/mcp.json` are **not** tracked: the first hardcodes absolute
hook paths that only exist on one machine, the second can hold credentials. The same applies to
`~/.codex/config.toml` — it carries machine-specific MCP server paths, so only the `agents/`
subdirectory is tracked; the `[agents]` block that enables Codex's multi-agent tools has to be added
to `config.toml` by hand on each machine. Set these up per machine.

See [CLAUDE.md](CLAUDE.md) for the full rationale and current migration status.

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow` on macOS)
- `git`, `curl`, `tar` for the tool installers in `scripts/`
