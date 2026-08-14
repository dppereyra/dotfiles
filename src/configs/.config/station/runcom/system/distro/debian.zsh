update-system() {
  sudo apt update -y
  sudo apt upgrade -y
}

update-all() {
  update-system
  update-envs
}
