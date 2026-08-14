update-system() {
  sudo pacman -Syu
  yay -Syu --aur
}

update-mirrors() {
  sudo reflector \
    -a 24 \
    -f 50 \
    -l 200 \
    --verbose \
    --threads 10 \
    -p https,http,ftp \
    --download-timeout 60 \
    --connection-timeout 30 \
    --save /etc/pacman.d/mirrorlist
}

update-all() {
  update-mirrors
  update-system
  update-envs
}

alias pacman='sudo pacman --color auto'
alias pac-recent="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -100"
alias pac-cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias pac-unlock="sudo rm /var/lib/pacman/db.lck"
alias yayskip='yay -S --mflags --skipinteg'
