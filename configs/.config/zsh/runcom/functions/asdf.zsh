asdf-ig() {
  asdf install $1 $2
  asdf set $1 $2
}

asdf-pl() {
  asdf plugin add $1
  asdf list all $1
}

asdf-plig() {
  asdf plugin add $1
  latest=`asdf list all $1 | tail -n 1`
  asdf install $1 $latest
  asdf global $1 $latest
}
