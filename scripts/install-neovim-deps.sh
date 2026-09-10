#!/usr/bin/env bash
#
# Installs the external tooling the neovim config needs.
#
# install-neovim.sh installs the editor and clones the config
# (gitlab.com/dppereyra/nvim-conf); this script installs everything that config
# shells out to. Run it after install-neovim.sh, then open nvim once so lazy.nvim
# and mason can do their own installs.
#
# What needs what, from the config itself:
#   git make unzip curl tar gzip  lazy.nvim clones; mason downloads and unpacks
#   cc, cmake, pkg-config         nvim-treesitter parsers, telescope-fzf-native's
#                                 `make` build, luasnip's `make install_jsregexp`
#   ripgrep                       telescope live_grep; lua/core/config-health.lua
#                                 checks for it explicitly
#   fd                            telescope and neo-tree file finding
#   node + npm                    mason's ansiblels, astro, azure_pipelines_ls,
#                                 dockerls, docker_compose_language_service,
#                                 graphql, prismals, ts_ls; copilot.lua
#   python3 + pip + venv          mason's pylsp; neotest-python (pytest); debugpy
#   deno                          peek.nvim's `deno task build:fast` build step
#   markdownlint-cli              the only linter nvim-lint is configured with
#   mcp-hub                       mcphub.nvim, a codecompanion.nvim dependency
#   sqlite3                       codecompanion.nvim reads the Copilot token out
#                                 of Copilot's own sqlite database
#   readline + imagemagick        lazy.nvim builds its own Lua 5.1 through
#     development headers         hererocks to get luarocks, and luarocks builds
#                                 the `magick` rock that image.nvim (a neo-tree
#                                 dependency) needs. Without readline/readline.h
#                                 the Lua build fails outright, which is what
#                                 leaves lazy-rocks/hererocks/bin half-written.
#   go                            mason gopls, nvim-dap's delve, neotest-golang.
#                                 Installed through goenv — see the note below.
#   tree-sitter                   only :TSInstallFromGrammar needs it; installed
#                                 because it is one npm package and it is the
#                                 last nvim-treesitter warning left otherwise
#
# Optional extras (--all), for the language- and TUI-specific plugins:
#   zig              mason zls, neotest-zig
#   rust-analyzer    rustaceanvim
#   lldb             the DAP adapter neotest-zig is configured with
#   lazygit lazydocker k9s mc
#                    the toggleterm integrations in lua/core/terminal.lua
#
# Runtimes (node, python, zig, rust) are only installed from packages when
# missing entirely — on a personal machine they usually come from the *env
# managers in install-{node,py,go}env.sh, and a distro package on top of those
# just shadows or duplicates them. Go is the exception that proves the rule:
# install-goenv.sh only *clones* goenv, and a goenv with no Go installed leaves
# `go` off PATH entirely, so this script runs the `goenv install` that actually
# produces a toolchain rather than layering a distro golang-go over the shims.
#
# Python is the other exception: python3 being present says nothing about pip,
# which Debian and Ubuntu package separately, so the two are checked apart.
#
# Usage: install-neovim-deps.sh [--minimal | --all] [--check]
#   --minimal  only the build tools and search tools; no runtimes, no npm CLIs
#   --all      also the optional language toolchains and TUI integrations
#   --check    install nothing, just report what is present and what is missing

set -euo pipefail

STATION_HOME="$HOME/.config/station"
NPM_PREFIX="$STATION_HOME/npm"
DENO_INSTALL="$STATION_HOME/sdk/deno"
GOENV_ROOT="${GOENV_ROOT:-$STATION_HOME/envs/goenv}"

# station/runcom/s04_paths.zsh already puts all of these on PATH; export them
# here too so this script's own checks see what it just installed. The goenv
# shims dir is what actually carries `go` once a version is installed — zsh gets
# it from `goenv init -` in s09_completions.zsh, which does not run here.
export PATH="$NPM_PREFIX/bin:$STATION_HOME/bin:$HOME/.local/bin:$DENO_INSTALL/bin:$GOENV_ROOT/bin:$GOENV_ROOT/shims:$PATH"

MODE=default
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal) MODE=minimal ;;
    --all)     MODE=all ;;
    --check)   CHECK_ONLY=1 ;;
    -h|--help) sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//;$d'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

log()  { printf -- '-- %s\n' "$*"; }
note() { printf -- '  ~ %s\n' "$*"; }
warn() { printf -- '  ! %s\n' "$*" >&2; }

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    warn "need root for: $*"
    return 1
  fi
}

PKG_MANAGER=""
for candidate in brew apt-get dnf pacman apk zypper; do
  if command -v "$candidate" &>/dev/null; then
    PKG_MANAGER="$candidate"
    break
  fi
done

if [[ -z "$PKG_MANAGER" ]]; then
  warn "no known package manager found; everything below has to be installed by hand"
fi

APT_UPDATED=0

install_packages() {
  local pkgs=("$@")
  [[ "${#pkgs[@]}" -gt 0 ]] || return 0

  case "$PKG_MANAGER" in
    brew)    brew install "${pkgs[@]}" ;;
    apt-get)
      # One update per run, not one per group.
      if [[ "$APT_UPDATED" -eq 0 ]]; then
        as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq
        APT_UPDATED=1
      fi
      as_root env DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends "${pkgs[@]}"
      ;;
    dnf)     as_root dnf install -y "${pkgs[@]}" ;;
    pacman)  as_root pacman -Sy --needed --noconfirm "${pkgs[@]}" ;;
    apk)     as_root apk add --no-cache "${pkgs[@]}" ;;
    zypper)  as_root zypper --non-interactive install "${pkgs[@]}" ;;
    *)       warn "install manually: ${pkgs[*]}"; return 1 ;;
  esac
}

# Package names for a logical group, per package manager. An empty result means
# this manager has no package for it and the caller has to say so.
packages_for() {
  local group="$1"
  case "$group:$PKG_MANAGER" in
    build:brew)     echo "cmake pkg-config" ;;
    build:apt-get)  echo "build-essential cmake pkg-config" ;;
    build:dnf)      echo "gcc gcc-c++ make cmake pkgconf-pkg-config" ;;
    build:pacman)   echo "base-devel cmake pkgconf" ;;
    build:apk)      echo "build-base cmake pkgconf" ;;
    build:zypper)   echo "gcc gcc-c++ make cmake pkg-config" ;;

    tools:brew)     echo "git curl ripgrep fd" ;;
    tools:apt-get)  echo "git make unzip curl tar gzip ripgrep fd-find" ;;
    tools:dnf)      echo "git make unzip curl tar gzip ripgrep fd-find" ;;
    tools:pacman)   echo "git make unzip curl tar gzip ripgrep fd" ;;
    tools:apk)      echo "git make unzip curl tar gzip ripgrep fd" ;;
    tools:zypper)   echo "git make unzip curl tar gzip ripgrep fd" ;;

    node:brew)      echo "node" ;;
    node:apk)       echo "nodejs npm" ;;
    node:*)         echo "nodejs npm" ;;

    python:brew)    echo "python" ;;
    python:apt-get) echo "python3 python3-pip python3-venv" ;;
    python:pacman)  echo "python python-pip" ;;
    python:apk)     echo "python3 py3-pip" ;;
    python:*)       echo "python3 python3-pip" ;;

    # hererocks compiles Lua 5.1 from source, and that build hard-requires
    # readline.h. imagemagick's headers are what the `magick` rock links against.
    rocks:brew)     echo "readline imagemagick" ;;
    rocks:apt-get)  echo "libreadline-dev libmagickwand-dev" ;;
    rocks:dnf)      echo "readline-devel ImageMagick-devel" ;;
    rocks:pacman)   echo "readline imagemagick" ;;
    rocks:apk)      echo "readline-dev imagemagick-dev" ;;
    rocks:zypper)   echo "readline-devel ImageMagick-devel" ;;

    # The sqlite3 CLI, not the library: codecompanion shells out to it.
    sqlite:brew)    echo "sqlite" ;;
    sqlite:apt-get) echo "sqlite3" ;;
    sqlite:zypper)  echo "sqlite3" ;;
    sqlite:*)       echo "sqlite" ;;

    go:apt-get)     echo "golang-go" ;;
    go:dnf)         echo "golang" ;;
    go:*)           echo "go" ;;

    zig:apt-get)    echo "" ;;   # not packaged for Debian/Ubuntu
    zig:*)          echo "zig" ;;

    lldb:brew)      echo "llvm" ;;
    lldb:*)         echo "lldb" ;;

    *)              echo "" ;;
  esac
}

install_group() {
  local group="$1" pkgs
  read -r -a pkgs <<<"$(packages_for "$group")"
  if [[ "${#pkgs[@]}" -eq 0 ]]; then
    warn "no '$group' package for $PKG_MANAGER — install it by hand"
    return 0
  fi
  install_packages "${pkgs[@]}"
}

# Debian and Fedora ship the fd binary as `fdfind`/`fd-find` to avoid a name
# clash with an unrelated package. Everything in the config calls it `fd`.
link_fd() {
  command -v fd &>/dev/null && return 0
  local found
  found="$(command -v fdfind || command -v fd-find || true)"
  [[ -n "$found" ]] || return 0
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$found" "$HOME/.local/bin/fd"
  note "linked $found -> ~/.local/bin/fd"
}

install_deno() {
  command -v deno &>/dev/null && { note "deno already installed"; return 0; }

  case "$PKG_MANAGER" in
    brew|pacman)
      install_packages deno
      ;;
    *)
      # No deno package on the other managers; the official installer drops a
      # single static binary, so put it under $STATION_SDK and link it into
      # $STATION_BIN, both of which are already on PATH.
      log "Installing deno into $DENO_INSTALL"
      curl -fsSL https://deno.land/install.sh | DENO_INSTALL="$DENO_INSTALL" sh -s -- -y
      mkdir -p "$STATION_HOME/bin"
      ln -sfn "$DENO_INSTALL/bin/deno" "$STATION_HOME/bin/deno"
      ;;
  esac
}

# npm's default global prefix is often a root-owned /usr, so `npm install -g`
# dies with EACCES for an unprivileged user. Install into the station prefix
# instead — install-paths.sh creates it and s04_paths.zsh has it on PATH.
install_npm_cli() {
  local pkg="$1" binary="$2"
  if command -v "$binary" &>/dev/null; then
    note "$binary already installed"
    return 0
  fi
  if ! command -v npm &>/dev/null; then
    warn "npm not available, skipping $pkg"
    return 0
  fi
  mkdir -p "$NPM_PREFIX"
  npm install -g --prefix "$NPM_PREFIX" "$pkg"
}

# python3 being on PATH says nothing about pip: Debian and Ubuntu split it into
# python3-pip, and mason's health check shells out to `python3 -m pip`. venv is
# split out too (python3-venv), and mason builds its pylsp/debugpy environments
# with it, so both are checked separately rather than inferred from python3.
python_bits_missing() {
  local missing=()
  command -v python3 &>/dev/null || { echo "python3"; return 0; }
  python3 -m pip --version &>/dev/null   || missing+=("pip")
  python3 -m ensurepip --version &>/dev/null || missing+=("venv")
  printf '%s\n' "${missing[@]:-}"
}

# install-goenv.sh clones goenv but installs no Go, so `go` is off PATH until
# something runs `goenv install`. Doing it here keeps Go under the same version
# manager as python/node instead of layering a distro package over the shims.
install_go() {
  # `command -v go` proves nothing here: goenv creates a shim as soon as any
  # version is installed, and that shim resolves to a path from every directory
  # while still exiting 127 unless a version is actually selected. Run it.
  if go version &>/dev/null; then
    note "go already installed ($(go version))"
    return 0
  fi

  if [[ ! -x "$GOENV_ROOT/bin/goenv" ]]; then
    warn "no goenv at $GOENV_ROOT — run install-goenv.sh first"
    warn "falling back to the $PKG_MANAGER go package"
    install_group go
    return 0
  fi

  export GOENV_ROOT

  # Not `goenv latest`: that reports the newest version matching the *current*
  # selection, so it returns empty when nothing is selected — even with a
  # toolchain already sitting in versions/. `--bare` lists what is installed.
  local version
  version="$(goenv versions --bare 2>/dev/null | sort -V | tail -1)"

  if [[ -z "$version" ]]; then
    log "No Go installed under goenv yet — installing the latest"
    goenv install -s latest
    version="$(goenv versions --bare | sort -V | tail -1)"
  else
    note "goenv already has Go $version installed but not selected"
  fi

  # This is the actual reason nvim reports `go` missing. Without a *global*
  # version the shims only resolve inside a directory carrying its own
  # .go-version, so `go` works in one project and nowhere else. `goenv global`
  # prints "system" rather than failing when nothing has been set.
  if [[ "$(goenv global 2>/dev/null)" == system ]]; then
    log "Setting the goenv global Go version to $version"
    goenv global "$version"
  fi
  goenv rehash
}

install_rust_analyzer() {
  if command -v rust-analyzer &>/dev/null; then
    note "rust-analyzer already installed"
    return 0
  fi
  if command -v rustup &>/dev/null; then
    rustup component add rust-analyzer
  else
    warn "rustup not installed; rustaceanvim needs rust-analyzer (https://rustup.rs)"
  fi
}

install_tui_integrations() {
  # lua/core/terminal.lua binds these to <leader>c*. Packaging is inconsistent
  # across distros, so install what this manager has and name what it does not.
  local wanted=(lazygit lazydocker k9s mc) missing=() tool
  for tool in "${wanted[@]}"; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  [[ "${#missing[@]}" -gt 0 ]] || { note "toggleterm integrations already installed"; return 0; }

  case "$PKG_MANAGER" in
    brew)
      install_packages "${missing[@]}"
      ;;
    pacman)
      # lazydocker is AUR-only.
      local avail=()
      for tool in "${missing[@]}"; do
        [[ "$tool" == lazydocker ]] || avail+=("$tool")
      done
      if [[ "${#avail[@]}" -gt 0 ]]; then
        install_packages "${avail[@]}"
      fi
      if [[ " ${missing[*]} " == *" lazydocker "* ]]; then
        warn "lazydocker is AUR-only: https://github.com/jesseduffield/lazydocker"
      fi
      ;;
    *)
      # Only mc is reliably packaged elsewhere; the Go TUIs ship as releases.
      if [[ " ${missing[*]} " == *" mc "* ]]; then
        install_packages mc
      fi
      for tool in lazygit lazydocker k9s; do
        [[ " ${missing[*]} " == *" $tool "* ]] || continue
        warn "$tool has no $PKG_MANAGER package — install from its releases page"
      done
      ;;
  esac
}

report() {
  echo
  echo "== neovim dependency report =="

  local tool path
  for tool in git make unzip curl tar gzip cc cmake pkg-config rg fd sqlite3 \
              node npm python3 deno markdownlint mcp-hub tree-sitter \
              go zig cargo rust-analyzer lldb lazygit lazydocker k9s mc; do
    path="$(command -v "$tool" 2>/dev/null || true)"
    if [[ -n "$path" ]]; then
      # A goenv shim has a path even when no version is selected; it only fails
      # when run. Reporting that as 'ok' is how this stayed hidden.
      if [[ "$tool" == go ]] && ! go version &>/dev/null; then
        printf '  BROKEN  %-14s %s (goenv shim, no version selected)\n' "$tool" "$path"
        continue
      fi
      printf '  ok      %-14s %s\n' "$tool" "$path"
    else
      printf '  MISSING %-14s\n' "$tool"
    fi
  done

  echo
  if command -v nvim &>/dev/null; then
    local version raw major minor
    version="$(nvim --version | head -1)"
    # lua/core/plugin-manager.lua calls vim.uv and config-health.lua asserts
    # 0.10-dev or newer, so an older editor cannot load this config at all.
    # Parsed from --version rather than asked of a headless nvim: a headless
    # run loads the config, and that starts a lazy.nvim plugin install, which
    # is not something --check should ever set off.
    raw="$(printf '%s\n' "$version" | sed -n 's/^NVIM v\([0-9]\+\.[0-9]\+\).*/\1/p')"
    major="${raw%%.*}"
    minor="${raw##*.}"
    if [[ -n "$raw" ]] && { (( major > 0 )) || (( minor >= 10 )); }; then
      printf '  ok      %-14s %s\n' neovim "$version"
    else
      warn "$version is too old for this config — it needs 0.10 or newer"
      warn "run install-neovim.sh: it installs the official build when the distro package is too old"
    fi
  else
    printf '  MISSING %-14s (run install-neovim.sh first)\n' neovim
  fi

  cat <<'EOF'

Next steps:
  * Open nvim once and let lazy.nvim install plugins, then run
    :MasonToolsInstall to pull the language servers, and :checkhealth.
  * If luarocks was broken before this run, lazy.nvim has already cached the
    half-built tree — delete it so the Lua 5.1 build is retried now that
    readline.h is present:  rm -rf ~/.local/share/nvim/lazy-rocks
  * :checkhealth still warns about Ruby, PHP, Java, Julia and Composer. That is
    mason listing languages it *could* manage, not anything missing for this
    config — lua/core/config-health.lua says as much in its own health output.
  * A Nerd Font is assumed (vim.g.have_nerd_font) — that is a terminal-app
    setting, not something installable from here.
  * Anything listed MISSING above only matters for the plugins that use it;
    see the header of this script for the mapping.
EOF
}

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  report
  exit 0
fi

log "Installing build tools (treesitter parsers, telescope-fzf-native, jsregexp)"
install_group build

log "Installing search and archive tools (telescope, lazy.nvim, mason)"
install_group tools
link_fd

if [[ "$MODE" != minimal ]]; then
  if command -v node &>/dev/null && command -v npm &>/dev/null; then
    note "node already installed ($(node --version))"
  else
    log "Installing node (mason's npm-based language servers, copilot.lua)"
    install_group node
  fi

  # Not `command -v python3` alone: pip and venv are separate packages, and a
  # python3 without pip is exactly what mason's health check complains about.
  missing_python="$(python_bits_missing)"
  if [[ -z "$missing_python" ]]; then
    note "python3 already installed with pip and venv ($(python3 --version 2>&1))"
  else
    log "Installing python — missing: $(echo $missing_python) (mason's pylsp, neotest-python)"
    install_group python
  fi

  log "Installing the luarocks build deps (hererocks' Lua 5.1, image.nvim's magick rock)"
  install_group rocks

  log "Installing sqlite3 (codecompanion reads the Copilot token from it)"
  install_group sqlite

  log "Installing go via goenv (gopls, delve, neotest-golang)"
  install_go

  log "Installing deno (peek.nvim's build step)"
  install_deno

  log "Installing npm CLIs into $NPM_PREFIX"
  install_npm_cli markdownlint-cli markdownlint
  install_npm_cli mcp-hub mcp-hub
  install_npm_cli tree-sitter-cli tree-sitter
fi

if [[ "$MODE" == all ]]; then
  if command -v zig &>/dev/null; then
    note "zig already installed ($(zig version))"
  else
    log "Installing zig (zls, neotest-zig)"
    install_group zig
  fi

  log "Installing rust-analyzer (rustaceanvim)"
  install_rust_analyzer

  log "Installing lldb (the neotest-zig DAP adapter)"
  install_group lldb

  log "Installing the toggleterm integrations from lua/core/terminal.lua"
  install_tui_integrations
fi

report
