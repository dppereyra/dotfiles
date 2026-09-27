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
3. `stow` both packages: `src/configs` → `$HOME`, `src/scripts` → `$HOME/.config/scripts`.
4. Run every installer in `scripts/` (asdf, pyenv, goenv, nodenv, rbenv, phpenv, zinit, opencode, claude, gh, az, worktrunk, neovim, neovim deps, git-town, tmux plugin manager).

`install-neovim.sh` installs the editor and clones the config. The config needs neovim 0.10 or
newer (`plugin-manager.lua` calls `vim.uv`), which not every distro can supply: Arch-based and
Fedora packages are current and macOS gets the Homebrew formula, but Debian's is 0.7 and Ubuntu's
is pinned at 0.9.5. So the installer uses the package manager where that works, verifies the
version it actually got, and falls back to the official static tarball otherwise — extracted to
`$STATION_SDK/neovim` and symlinked into `$STATION_BIN`, which `s04_paths.zsh` puts ahead of
`/usr/bin`. Pin a specific build with `NVIM_VERSION=v0.11.2`.

`install-neovim-deps.sh`
installs the external tooling that config shells out to (build tools for treesitter and
telescope-fzf-native, ripgrep and fd, node/python for mason's language servers, deno for
peek.nvim, markdownlint-cli and mcp-hub). Its header documents which plugin needs what. Run
it with `--check` to report without installing, `--minimal` for build and search tools only,
or `--all` to add the optional toolchains (go, zig, lldb, rust-analyzer) and the toggleterm
integrations from `lua/core/terminal.lua` (lazygit, lazydocker, k9s, mc).

Each installer in `scripts/` is also safe to run standalone: clone the repo and run just the
installer(s) you need, e.g. `scripts/install-neovim.sh`.

## Ephemeral environments (DevPod, Codespaces, Gitpod/Ona)

Use `install.sh`, not `bootstrap.sh`:

```bash
devpod up . --dotfiles https://github.com/dppereyra/dotfiles
```

DevPod clones this repo to `~/dotfiles` inside the container and runs the first script it finds
from `install.sh`, `install`, `bootstrap.sh`, `bootstrap`, `script/bootstrap`, `setup.sh`, `setup`
— so `install.sh` is picked up automatically with no `--dotfiles-script` flag. GitHub Codespaces
and Gitpod/Ona use the same convention.

`install.sh` differs from `bootstrap.sh` in three ways, each forced by the container context:

- **It installs its own prerequisites** (`stow`, `git`, `curl`, `zsh`). `bootstrap.sh` exits 1 when
  `stow` is missing, which would fail the whole `devpod up`.
- **It backs conflicting files out of the way** rather than aborting. Base images ship their own
  `~/.zshrc`; on a personal machine that collision means "stop and look", in a disposable container
  it means "ours wins". Displaced files are never deleted — they are renamed to
  `<name>.pre-dotfiles`.
- **It runs only the installers that work unattended** — by default `install-paths.sh`,
  `install-zinit.sh`, `install-opencode.sh`, `install-claude.sh`. Excluded are the ones that need
  an SSH key (`install-neovim.sh`), compile C (`install-rbenv.sh`), require interaction
  (`install-tmux-plugins.sh`), install system packages as root (`install-neovim-deps.sh`), or
  spend several minutes cloning language runtimes (`install-{py,go,node,php}env.sh`).

Override that set per workspace:

```bash
devpod up . --dotfiles https://github.com/dppereyra/dotfiles \
  --dotfiles-script-env DOTFILES_INSTALLERS="install-paths.sh install-asdf.sh install-pyenv.sh"
```

Or make it the default for every workspace in the context:

```bash
devpod context set-options -o DOTFILES_URL=https://github.com/dppereyra/dotfiles
```

`install.sh` is idempotent — re-running it on an existing container is a no-op. A failing installer
is reported at the end but does not fail the run, so one broken tool cannot cost you the whole
environment.

Note that `install-claude.sh` and `install-opencode.sh` both need `npm`, which minimal base images
do not ship. Add a Node runtime in the devcontainer (e.g. the
`ghcr.io/devcontainers/features/node:1` feature) or those two will report a failure and skip.

## Claude Code on the web (cloud environments)

Use `claude-cloud-setup.sh`. In the cloud environment's settings, paste this into **Setup
script**:

```bash
#!/bin/bash
DOTFILES_DIR="$HOME/.dotfiles"
if [ -d "$DOTFILES_DIR/.git" ]; then
  git -C "$DOTFILES_DIR" pull --ff-only --quiet || true
else
  git clone --depth 1 https://github.com/dppereyra/dotfiles "$DOTFILES_DIR" || exit 0
fi
"$DOTFILES_DIR/claude-cloud-setup.sh" || true
```

The paste-in only clones and delegates, so changing what a cloud session gets is a commit here,
not a settings edit. It installs:

| Tool | How | Fallback |
|---|---|---|
| `gh` | GitHub's apt repo (`cli.github.com`) | Ubuntu's `gh` package when that host is blocked |
| `az` | Microsoft's apt repo (`packages.microsoft.com`) | `uv tool install azure-cli` from PyPI |
| `wt` (worktrunk) | prebuilt musl binary from the GitHub release | `cargo install` from crates.io, updating Rust through rustup if it is too old |
| `git-town` | `go install` through the Go module proxy | — |
| `delta`, `git-lfs`, `shellcheck`, `fd`, `tree` | distro packages | — |

It also links the agent fleet into `~/.claude/agents` and each skill into `~/.claude/skills/`,
includes this repo's `.gitconfig` from `~/.config/git/config`, and adds worktrunk's bash
integration to `~/.bashrc` (so `wt switch` can change directory).

Why it is not `install.sh`: the cloud container is not a blank image. `~/.gitconfig` is written by
the session itself (commit identity, SSH signing, proxy settings), so stowing ours over it breaks
every commit — ours is layered in through `~/.config/git/config`, which git reads first, so the
session's values win on overlap. `~/.claude/skills` already holds platform-shipped skills, so it
cannot become a symlink. And with no interactive terminal, zsh/tmux/neovim are dead weight.

Every step reports and carries on, and the script always exits 0, so one blocked package host
cannot cost the session. Override the installer set with `CLOUD_INSTALLERS` or add distro
packages with `CLOUD_APT_PACKAGES` in the environment's variables. Credentials go there too,
never in this repo: `GH_TOKEN` (read by `gh` directly), and `AZURE_CLIENT_ID` /
`AZURE_TENANT_ID` / `AZURE_CLIENT_SECRET` for `az login --service-principal`.

The four new installers (`install-gh.sh`, `install-az.sh`, `install-worktrunk.sh`,
`install-git-town.sh`) are ordinary `scripts/install-*.sh` — `bootstrap.sh` runs them too, and
DevPod can opt in through `DOTFILES_INSTALLERS`.

## What's not automated (manual steps)

- **tmux plugins**: `bootstrap.sh` clones TPM (tmux plugin manager) to `~/.tmux/plugins/tpm`, but the actual plugin install has to happen interactively — open tmux and press `prefix + I`.
- **fzf / fd**: referenced by the `tmux-fzf` / `tmux-fzf-url` plugins and general shell use, but not installed by any script here — install with your package manager, e.g. `brew install fzf fd`.
- **gitmux / lazygit**: referenced by `.tmux.conf`'s catppuccin status segments — install with your package manager if not already present.
- **Real secrets**: `~/.config/station/runcom/s97_work_config.sample.zsh` and `s98_secrets.sample.zsh` are templates. Copy them to `s97_work_config.zsh` / `s98_secrets.zsh` and fill in real values — both stay untracked (gitignored via `~/.config/station/global_gitignore`), never commit real values.
- **A Nerd Font**: needed for the catppuccin theming in tmux/p10k — this is a terminal-app setting, not something a script can install for you.

## Stow packages

A `.stowrc` at the repo root sets `--dir=src` by default, so run these from the repo root:

```bash
stow --target=$HOME configs                  # dotfiles -> $HOME
stow --target=$HOME/.config/scripts scripts  # shell utility scripts -> ~/.config/scripts
```

The `scripts` package targets `~/.config/scripts`, not `~/.config`. Stow links a package's
*contents* into the target, so the older `--target=$HOME/.config` produced `~/.config/clean-all-py`,
`~/.config/download-common-images` and `~/.config/git` — which left `$STATION_SCRIPTS`
(`~/.config/scripts`, put on `PATH` by `runcom/s04_paths.zsh`) pointing at a directory that never
existed, and dropped the git hooks package on top of `~/.config/git`, git's own XDG config
directory. `bootstrap.sh` and `install.sh` both remove the stale links from the old layout.

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
