#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ENV_ROOT="$STATION_HOME/envs/rbenv"

if [[ -d "$ENV_ROOT/.git" ]]; then
  echo "rbenv already installed at $ENV_ROOT"
  exit 0
fi

echo "Install rbenv ..."
git clone https://github.com/rbenv/rbenv.git "$ENV_ROOT"
(cd "$ENV_ROOT" && src/configure && make -C src)
git clone https://github.com/rbenv/ruby-build.git "$ENV_ROOT/plugins/ruby-build"
git clone https://github.com/rkh/rbenv-update.git "$ENV_ROOT/plugins/rbenv-update"
