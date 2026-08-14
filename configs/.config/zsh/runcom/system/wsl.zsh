echo "Loading wsl specific configs"

winPaths=(
  "/usr/lib/wsl/lib"
  "/mnt/c/Windows"
  "/mnt/c/Windows/System32"
  "/mnt/c/Windows/System32/Wbem"
  "/mnt/c/Program Files/Microsoft VS Code/bin"
  "/mnt/c/opt/bin"
  "/mnt/c/users/DennisPereyra/scoop/shims"
)

for winPath in $winPaths
do
  export PATH=$PATH:$winPath
done

export XDG_CONFIG_HOME=~/.config

export VAGRANT_DEFAULT_PROVIDER=hyperv
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/projects"
