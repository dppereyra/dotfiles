##############################################################################
#
#    dppereyra's personal zsh config
#
#    zsh aliases
#
##############################################################################

echo "Loading aliases ..."

alias mystation="git --git-dir=$HOME/.station --work-tree=$HOME"
alias mystation-tui="lazygit --git-dir=$HOME/.station --work-tree=$HOME"

alias vi="nvim"

alias asdf-la="asdf list all"
alias asdf-pa="asdf plugin add"

alias show="pygmentize -f terminal256 -g -P style=paraiso-dark";

alias aria2c='aria2c -x 10 -s 10'
alias wget="wget -c"

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias ls='ls -G --color=auto'
alias la='ls -AG --color=auto'
alias ll='ls -AGlh --color=auto'
alias lr='ls -AGlhr --color=auto'
alias lh="ls -AG --color=auto | egrep '^\.'"

alias fc='sudo fc-cache -fv'

alias df='df -h'
alias free="free -mt"

alias ps="ps aeux"
alias psgrep="ps aeux | grep -v grep | grep -i -e VSZ -e"

alias hw="hwinfo --short"
alias cpu-security-check='grep . /sys/devices/system/cpu/vulnerabilities/*'

alias userlist="cut -d: -f1 /etc/passwd"

alias update-gcloud="gcloud components update"

alias k8s-clear-conf="mv ~/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)"
alias k8s-namespace="kubectl config set-context $(kubectl config current-context) --namespace"
