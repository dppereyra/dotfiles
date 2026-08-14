#!/usr/bin/env bash
set -euo pipefail

TPM_HOME="$HOME/.tmux/plugins/tpm"

if [[ -d "$TPM_HOME/.git" ]]; then
  echo "TPM already installed at $TPM_HOME"
else
  echo "Cloning TPM (tmux plugin manager) ..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"
fi

echo "TPM ready. Open tmux and press 'prefix + I' to install the plugins listed in .tmux.conf."
