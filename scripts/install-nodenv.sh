#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ENV_ROOT="$STATION_HOME/envs/nodenv"

if [[ -d "$ENV_ROOT/.git" ]]; then
  echo "nodenv already installed at $ENV_ROOT"
  exit 0
fi

echo "Install nodenv ..."
git clone https://github.com/nodenv/nodenv.git                 "$ENV_ROOT"
git clone https://github.com/nodenv/node-build.git             "$ENV_ROOT/plugins/node-build"
git clone https://github.com/nodenv/nodenv-package-rehash.git  "$ENV_ROOT/plugins/nodenv-package-rehash"
git clone https://github.com/nodenv/nodenv-update.git          "$ENV_ROOT/plugins/nodenv-update"
git clone https://github.com/nodenv/node-build-update-defs.git "$ENV_ROOT/plugins/node-build-update-defs"
