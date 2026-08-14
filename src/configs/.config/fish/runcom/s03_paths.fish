##############################################################################
#
#    dppereyra's personal fish config
#
#    fish paths
#
##############################################################################

echo "Setting paths ..."

set -xg PROJECT_HOME ~/projects

set -xg STATION_BIN     $STATION_HOME/bin
set -xg STATION_SCRIPTS $STATION_HOME/scripts
set -xg STATION_ENV     $STATION_HOME/envs
set -xg STATION_SDK     $STATION_HOME/sdk

set -xg NPM_BIN $STATION_HOME/npm/bin

set -xg ASDF_DIR $STATION_HOME/asdf
set -xg ASDF_BIN ~/.asdf/bin

set -xg CARGO_BIN ~/.cargo/bin

set -xg LOCAL_BIN ~/.local/bin

set -xg GCLOUD_BIN  $STATION_SDK/google-cloud-sdk/bin
set -xg FLUTTER_BIN $STATION_SDK/flutter/bin

set -xg ANDROID_HOME           $STATION_SDK/android
set -xg ANDROID_PLATFORM_TOOLS $ANDROID_HOME/platform-tools

set -xg PYENV_ROOT $STATION_ENV/pyenv
set -xg PYENV_BIN  $PYENV_ROOT/bin

set -xg GOENV_ROOT $STATION_ENV/goenv
set -xg GOENV_BIN  $GOENV_ROOT/bin

set -xg RBENV_ROOT $STATION_ENV/rbenv
set -xg RBENV_BIN  $RBENV_ROOT/bin

set -xg NODENV_ROOT $STATION_ENV/nodenv
set -xg NODENV_BIN  $NODENV_ROOT/bin

set -xg GOPATH $PROJECT_HOME/go
set -xg GO_BIN $GOPATH/bin

set -xg ENV_PATHS $ASDF_BIN $PYENV_BIN $GOENV_BIN $NODENV_BIN $RBENV_BIN
set -xg APP_PATHS $GO_BIN $CARGO_BIN $NPM_BIN $FLUTTER_BIN $GCLOUD_BIN

set -xg PATH $ENV_PATHS $APP_PATHS $STATION_SCRIPTS $STATION_BIN $LOCAL_BIN $PATH
