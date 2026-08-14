##############################################################################
#
#    dppereyra's personal zsh config
#
#    os specific configs
#
##############################################################################

echo "Determining os ..."

if [[ "$OSTYPE" == *"darwin"* ]]
then
  source $RC_HOME/system/apple.zsh
elif [[ "$OSTYPE" == *"linux-gnu"* || "$OSTYPE" == *"fc"* ]]
then
  source $RC_HOME/system/linux.zsh
else
  echo "No OS specific configs loaded ..."
fi
