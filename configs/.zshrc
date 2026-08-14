##############################################################################
#
#    DPPereyra's Personal ZSH config
#
##############################################################################

export STATION_HOME=~/station
export RC_HOME=~/.config/zsh/runcom

source $RC_HOME/s01_options.zsh
source $RC_HOME/s02_keybindings.zsh
source $RC_HOME/s03_variables.zsh
source $RC_HOME/s04_paths.zsh
source $RC_HOME/s05_os.zsh
source $RC_HOME/s06_function_loader.zsh
source $RC_HOME/s07_terminal.zsh
source $RC_HOME/s08_aliases.zsh
source $RC_HOME/s09_completions.zsh
source $RC_HOME/s10_zinit.zsh
source $RC_HOME/s99_theme.zsh

if [[ -v NEOFETCH_DISTRO ]]
then
  fastfetch --ascii_distro $NEOFETCH_DISTRO
else
  fastfetch
fi

fortune | cowsay -f small
