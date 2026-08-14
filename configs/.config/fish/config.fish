#########################################################################################
#
# DPPereyra's Personal Fish config
#
#########################################################################################

set -xg LC_ALL en_PH.UTF-8

set -xg STATION_HOME $HOME/station
set -xg FISH_HOME    $HOME/.config/fish
set -xg FISH_RUNCOM  $FISH_HOME/runcom

source $FISH_RUNCOM/s01_dependencies.fish
source $FISH_RUNCOM/s02_variables.fish
source $FISH_RUNCOM/s03_paths.fish
# source $FISH_RUNCOM/s04_os.fish
# source $FISH_RUNCOM/s05_function_loader.fish
# source $FISH_RUNCOM/s06_aliases.fish
# source $FISH_RUNCOM/s07_completions.fish

# source $FISH_RUNCOM/s98_secrets.fish

# source $FISH_RUNCOM/s99_theme.fish

# clear
# neofetch --ascii_distro $NEOFETCH_DISTRO
# fortune | cowsay -f small | lolcat

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/dppereyra/.cache/lm-studio/bin
# End of LM Studio CLI section

