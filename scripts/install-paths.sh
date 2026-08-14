#!/usr/bin/env bash
set -euo pipefail

STATION_HOME=~/.config/station

mkdir -p "$STATION_HOME/envs"
mkdir -p "$STATION_HOME/ansible/roles"
mkdir -p "$STATION_HOME/appimages"
mkdir -p "$STATION_HOME/bin"
mkdir -p "$STATION_HOME/npm"
mkdir -p "$STATION_HOME/sdk"
mkdir -p "$STATION_HOME/zinit"
mkdir -p "$HOME/.local/bin"

echo "Station directories ready under $STATION_HOME"
