station-edit() {
  case "$1" in
    "zellij")
      TARGET=~/.config/zellij
      ;;
    "nvim")
      TARGET=~/.config/nvim
      ;;
    "runcom")
      TARGET=$STATION_HOME/runcom
  esac
  $EDITOR $TARGET
}
