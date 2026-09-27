#!/usr/bin/env bash
set -euo pipefail

# Installs the Azure CLI (az).
#
# On apt systems this uses Microsoft's own repository, which is what Microsoft
# supports. Not their `curl aka.ms/InstallAzureCLIDeb | bash` one-liner: that
# pipes a remote script into a root shell, and aka.ms is a redirector that
# restrictive egress policies tend to block even when packages.microsoft.com
# itself is allowed.
#
# Anywhere that does not work — no apt, a distro codename Microsoft has not
# published yet, the repo unreachable — fall back to the PyPI package through
# uv (or pipx), which lands `az` in ~/.local/bin without needing root.

export PATH="$HOME/.local/bin:$PATH"

if command -v az &>/dev/null; then
  echo "az already installed ($(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo unknown))"
  exit 0
fi

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    echo "  ! need root for: $*" >&2
    return 1
  fi
}

install_apt_microsoft() {
  local codename keyring=/etc/apt/keyrings/microsoft.asc
  local list=/etc/apt/sources.list.d/azure-cli.list
  local tmp

  codename="$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release 2>/dev/null)"
  [[ -n "$codename" ]] || return 1

  # Check the suite exists before touching sources.list.d, so a codename
  # Microsoft has not published yet goes straight to the fallback.
  curl -fsSL -m 30 -o /dev/null \
    "https://packages.microsoft.com/repos/azure-cli/dists/$codename/Release" || return 1

  tmp="$(mktemp)"
  if ! curl -fsSL -m 30 -o "$tmp" https://packages.microsoft.com/keys/microsoft.asc; then
    rm -f "$tmp"
    return 1
  fi

  # apt reads an ASCII-armored key directly when the file ends in .asc, so
  # there is no gpg --dearmor step and no gnupg dependency.
  as_root install -d -m 0755 /etc/apt/keyrings
  as_root install -m 0644 "$tmp" "$keyring"
  rm -f "$tmp"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://packages.microsoft.com/repos/azure-cli/ $codename main" \
    | as_root tee "$list" >/dev/null

  if ! as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq \
     || ! as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends azure-cli; then
    as_root rm -f "$list" "$keyring"
    return 1
  fi
}

install_from_pypi() {
  if command -v uv &>/dev/null; then
    uv tool install azure-cli
  elif command -v pipx &>/dev/null; then
    pipx install azure-cli
  else
    echo "Neither uv nor pipx available — install the Azure CLI manually: https://learn.microsoft.com/cli/azure/install-azure-cli" >&2
    return 1
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install azure-cli
elif command -v apt-get &>/dev/null && install_apt_microsoft; then
  :
else
  echo "  ~ no usable Microsoft apt repo here, installing azure-cli from PyPI"
  install_from_pypi
fi

echo "az installed: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo unknown)"
