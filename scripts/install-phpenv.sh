#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ENV_ROOT="$STATION_HOME/envs/phpenv"

if [[ -d "$ENV_ROOT/.git" ]]; then
  echo "phpenv already installed at $ENV_ROOT"
  exit 0
fi

echo "Install phpenv ..."
git clone https://github.com/phpenv/phpenv.git "$ENV_ROOT"
git clone https://github.com/php-build/php-build "$ENV_ROOT/plugins/php-build"
