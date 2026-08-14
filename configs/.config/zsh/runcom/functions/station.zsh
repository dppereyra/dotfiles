station-edit() {
  case "$1" in
    "zellij")
      TARGET=~/.config/zellij
      ;;
    "nvim")
      TARGET=~/.config/nvim
      ;;
    "runcom")
      TARGET=$RC_HOME
  esac
  $EDITOR $TARGET
}
