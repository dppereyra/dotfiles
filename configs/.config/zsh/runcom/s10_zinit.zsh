##############################################################################
#
#    dppereyra's personal zsh config
#
#    zinit plugins
#
##############################################################################

echo "Loading zinit plugins ..."

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust \
    zsh-users/zsh-syntax-highlighting \
    zsh-users/zsh-completions \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    bilelmoussaoui/flatpak-zsh-completion

# Shell
zinit snippet OMZ::plugins/colored-man-pages
zinit snippet OMZ::plugins/command-not-found

# Agents
zinit snippet OMZ::plugins/gpg-agent
zinit snippet OMZ::plugins/ssh-agent

# Applications
zinit snippet OMZ::plugins/paver
zinit snippet OMZ::plugins/taskwarrior
zinit snippet OMZ::plugins/zoxide

# Envs
# zinit snippet OMZ::plugins/asdf
zinit snippet OMZ::plugins/pyenv

# Virtualization / Containerization
# zinit snippet OMZP::docker/_docker
# zinit snippet OMZ::plugins/lxd
zinit snippet OMZ::plugins/istioctl
zinit snippet OMZ::plugins/vagrant

# Cloud Services
zinit snippet OMZ::plugins/aws
zinit snippet OMZ::plugins/azure
# zinit snippet OMZ::plugins/doctl
zinit snippet OMZ::plugins/gcloud

# Deployments
zinit snippet OMZ::plugins/ansible
zinit snippet OMZ::plugins/fabric
zinit snippet OMZ::plugins/terraform

# Languages
zinit snippet OMZ::plugins/golang
zinit snippet OMZ::plugins/pip

# Theme
# romkatv/powerlevel10k-remove-me
# denysdovhan/spaceship-prompt-remove-me
