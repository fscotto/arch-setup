#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

info "Installing base system packages..."

PACKAGES=(
  bat
  bruno-bin
  btop
  cmatrix
  dbeaver
  dconf-editor
  devtoolbox
  duf
  exercism
  exiftool
  eza
  fastfetch
  fd
  filezilla
  firefox
  freefilesync-bin
  fzf
  gcolor3
  gnome-boxes
  htop
  httpie
  hwinfo
  inotify-tools
  jq
  kitty
  koodo-reader
  masterpdfeditor-bin
  miller
  minicom
  neovim
  onlyoffice-desktopeditors
  papirus-icon-theme-dark
  pipx
  putty
  qalculate-gtk
  qemu
  ripgrep
  rsync
  rpi-imager
  seahorse
  solaar
  spotify
  starship
  stow
  sushi
  telegram-desktop
  thunderbird
  tmux
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
  ttf-roboto-mono-nerd
  ugrep
  unar
  vlc
  xclip
  xournalpp
  xsel
  zoxide
  zsh
)

for pkg in "${PACKAGES[@]}"; do
  if yay -Qi "$pkg" &>/dev/null; then
    info "$pkg ✔ already installed"
  else
    info "Installing $pkg"
    yay -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1
    success "$pkg installed"
  fi
done
