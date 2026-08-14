##############################################################################
#
#    dppereyra's personal fish config
#
#    fish dependencies
#
##############################################################################

if not functions -q fisher
    echo "Installing fisherman ..."
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
end
