##############################################################################
#
#    dppereyra's personal zsh config
#
#    zsh paths
#
##############################################################################

echo "Setting paths ..."

export PROJECT_HOME=~/projects

export STATION_SCRIPTS=$STATION_HOME/scripts
export STATION_ENV=$STATION_HOME/envs
export STATION_SDK=~/.local/sdk

export NPM_BIN=~/.local/npm/bin

export ASDF_DATA_DIR=~/.asdf
export ASDF_BIN=$ASDF_DATA_DIR/shims
export CARGO_BIN=~/.cargo/bin
export LOCAL_BIN=~/.local/bin
export ARKADE_BIN=~/.arkade/bin
export MODULAR_HOME=~/.modular
export MOJO_BIN=$MODULAR_HOME/pkg/packages.modular.com_mojo/bin
export RADICLE_BIN=~/.radicle/bin
export LMSTUDIO_BIN=~/.cache/lm-studio/bin

export GCLOUD_BIN=$STATION_SDK/google-cloud-sdk/bin
export FLUTTER_BIN=$STATION_SDK/flutter/bin

export ANDROID_HOME=$STATION_SDK/android
export ANDROID_PLATFORM_TOOLS=$ANDROID_HOME/platform-tools

export PYENV_ROOT=$STATION_ENV/pyenv
export PYENV_BIN=$PYENV_ROOT/bin

export GOENV_ROOT=$STATION_ENV/goenv
export GOENV_BIN=$GOENV_ROOT/bin

export RBENV_ROOT=$STATION_ENV/rbenv
export RBENV_BIN=$RBENV_ROOT/bin

export NODENV_ROOT=$STATION_ENV/nodenv
export NODENV_BIN=$NODENV_ROOT/bin

export GOPATH=$PROJECT_HOME/go
export GO_BIN=$GOPATH/bin

export PHPENV_ROOT=$STATION_ENV/phpenv
export PHPENV_BIN=$PHPENV_ROOT/bin

export PNPM_HOME=$STATION_HOME/pnpm

export ENV_PATHS=$ASDF_BIN:$PYENV_BIN:$GOENV_BIN:$NODENV_BIN:$RBENV_BIN:$PHPENV_BIN:$PNPM_HOME
export APP_PATHS=$GO_BIN:$CARGO_BIN:$NPM_BIN:$FLUTTER_BIN:$GCLOUD_BIN:$MOJO_BIN:$RADICLE_BIN:$ARKADE_BIN:$LMSTUDIO_BIN
export PATH=$ENV_PATHS:$APP_PATHS:$STATION_SCRIPTS:$LOCAL_BIN:$PATH
