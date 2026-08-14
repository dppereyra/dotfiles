echo "Loading linux specific configs ..."

STATION_KERNEL=$(uname -a | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
STATION_DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr '[:upper:]' '[:lower:]')

alias skel='cp -rf /etc/skel/* ~'
alias bupskel='cp -Rf /etc/skel ~/.skel-backup-$(date +%Y.%m.%d-%H.%M.%S)'

alias kill-conky='killall conky'

alias merge="xrdb -merge ~/.Xresources"

alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"

echo "Loading pipx completions ..."
eval "$(register-python-argcomplete pipx)"

if [[ "$STATION_KERNEL" == *wsl2* ]]
then
  source $STATION_RC/system/wsl.zsh
fi

case "$STATION_DISTRO" in
  *arch*)
    echo "Loading arch specific configs ..."
    source $STATION_RC/system/distro/arch.zsh
  ;;
  *arcolinux*)
    echo "Loading arch specific configs ..."
    source $STATION_RC/system/distro/arch.zsh
  ;;
  *endeavouros*)
    echo "Loading endeavour specific configs ..."
    source $STATION_RC/system/distro/arch.zsh
  ;;
  *debian*)
    echo "Loading debian specific configs ..."
    source $STATION_RC/system/distro/debian.zsh
  ;;
  *fedora*)
    echo "Loading fedora specific configs ..."
    source $STATION_RC/system/distro/fedora.zsh
  ;;
  *)
    echo "No OS specific configs loaded ..."
    ;;
esac
