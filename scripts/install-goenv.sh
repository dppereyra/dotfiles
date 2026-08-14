#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ENV_ROOT="$STATION_HOME/envs/goenv"

if [[ -d "$ENV_ROOT/.git" ]]; then
  echo "goenv already installed at $ENV_ROOT"
  exit 0
fi

echo "Install goenv ..."
git clone https://github.com/syndbg/goenv.git "$ENV_ROOT"
