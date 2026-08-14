##############################################################################
#
#    dppereyra's personal fish config
#
#    os specific configs
#
##############################################################################

echo "Determining os ..."

set -xg STATION_KERNEL $(uname -a | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
set -xg STATION_DISTRO $(awk -F= '/^NAME/{print $2}' /etc/os-release | tr '[:upper:]' '[:lower:]')

# if test $OSTYPE = "*linux-gnu*"; or test $OSTYPE = "*fc*"

#   if test $STATION_KERNEL = "*wsl2*"
#     echo "Loading wsl configs ..."
#     source $STATION_RC/system/wsl.fish
#   end

#   switch($STATION_DISTRO)
#   case *arch*

#   end

# end



# if [[ "$OSTYPE" == *"linux-gnu"* || "$OSTYPE" == *"fc"* ]]
# then
#   if [[ "$STATION_KERNEL" == *wsl2* ]]
#   then
#     echo "Loading wsl configs ..."
#     source $STATION_RC/system/wsl.zsh
#   fi

#   case "$STATION_DISTRO" in
#     *arch*)
#       echo "Loading arch specific configs ..."
#       export NEOFETCH_DISTRO="Arch"
#       source $STATION_RC/system/distro/arch.zsh
#     ;;
#     *arcolinux*)
#       echo "Loading arch specific configs ..."
#       export NEOFETCH_DISTRO="Arch"
#       source $STATION_RC/system/distro/arch.zsh
#     ;;
#     *debian*)
#       echo "Loading debian specific configs ..."
#       export NEOFETCH_DISTRO="Debian"
#       source $STATION_RC/system/distro/debian.zsh
#     ;;
#     *fedora*)
#       echo "Loading fedora specific configs ..."
#       export NEOFETCH_DISTRO="Fedora"
#       source $STATION_RC/system/distro/fedora.zsh
#     ;;
#     *nobara*)
#       echo "Loading fedora specific configs ..."
#       export NEOFETCH_DISTRO="Fedora"
#       source $STATION_RC/system/distro/fedora.zsh
#     ;;
#     *)
#       echo "No OS specific configs loaded ..."
#       export NEOFETCH_DISTRO="Linux"
#       ;;
#   esac
# fi

# touch $STATION_RC/s98_secrets.zsh
