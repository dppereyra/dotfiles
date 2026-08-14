#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ENV_ROOT="$STATION_HOME/envs/pyenv"

if [[ -d "$ENV_ROOT/.git" ]]; then
  echo "pyenv already installed at $ENV_ROOT"
  exit 0
fi

echo "Install pyenv ..."
git clone https://github.com/pyenv/pyenv.git                "$ENV_ROOT"
git clone https://github.com/pyenv/pyenv-virtualenv.git     "$ENV_ROOT/plugins/pyenv-virtualenv"
git clone https://github.com/pyenv/pyenv-which-ext.git      "$ENV_ROOT/plugins/pyenv-which-ext"
git clone https://github.com/pyenv/pyenv-update.git         "$ENV_ROOT/plugins/pyenv-update"
