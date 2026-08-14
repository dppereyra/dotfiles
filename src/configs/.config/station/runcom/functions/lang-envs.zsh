update-envs() {
  pyenv update
  nodenv update
  rbenv update
  git -C $GOENV_ROOT pull
  asdf plugin update --all
  rustup update
}
