update-system() {
  sudo dnf update -y --refresh
}

update-all() {
  update-system
  update-envs
}
