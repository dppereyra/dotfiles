##############################################################################
#
#    dppereyra's personal zsh config
#
#    zsh zinit, compinit, bash compatibilities
#
##############################################################################

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
    echo "Loading vte (tilix) terminal fixes ..."
    source /etc/profile.d/vte.sh
fi

echo "Loading terminal utilities ..."
source $STATION_HOME/zinit/zinit.zsh
autoload -Uz _zinit

(( ${+_comps} )) && _comps[zinit]=_zinit

echo "Loading bash compatibility ..."
autoload bashcompinit
bashcompinit
