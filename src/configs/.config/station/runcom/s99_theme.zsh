##############################################################################
#
#    dppereyra's personal zsh config
#
#    zsh theme
#
##############################################################################

echo "Configuring theme ..."


zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# function blastoff(){
#   echo "🚀"
# }
# starship_precmd_user_func="blastoff"

# eval "$(starship init zsh)"

# eval "$(oh-my-posh --init --shell zsh --config $STATION_HOME/powerlevel10k_classic.omp.json)"

