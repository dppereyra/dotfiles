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
  source $STATION_RC/system/apple.zsh
elif [[ "$OSTYPE" == *"linux-gnu"* || "$OSTYPE" == *"fc"* ]]
then
  source $STATION_RC/system/linux.zsh
else
  echo "No OS specific configs loaded ..."
fi
