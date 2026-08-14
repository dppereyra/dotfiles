#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station
ZINIT_HOME="$STATION_HOME/zinit"

if [[ -d "$ZINIT_HOME/.git" ]]; then
  echo "zinit already installed at $ZINIT_HOME"
  exit 0
fi

echo "Install zinit ..."
git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
