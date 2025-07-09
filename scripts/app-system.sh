#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

info "Installing base system packages..."

PACKAGES=(
  bat
  bluez
  bluez-utils
  blueman
  btop
  catppuccin-gtk-theme
  cmatrix
  dbeaver
  dconf-editor
  devtoolbox
  duf
  exercism
  eza
  fastfetch
  fd
  filezilla
  firefox
  freefilesync-bin
  fuzzel
  fzf
  gcolor3
  gnome-boxes
  gnupg
  htop
  httpie
  hwinfo
  hyprland
  hyprpaper
  inotify-tools
  jq
  kitty
  koodo-reader
  mako
  masterpdfeditor-bin
  neovim
  networkmanager
  nm-connection-editor
  onlyoffice-desktopeditors
  openssh
  papirus-icon-theme-dark
  pipewire
  pipewire-pulse
  pipx
  putty
  qalculate-gtk
  qemu
  ripgrep
  rpi-imager
  rsync
  seahorse
  solaar
  spotify
  starship
  stow
  sushi
  telegram-desktop
  thunar
  thunderbird
  tmux
  ttf-cascadia-code-nerd
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
  ttf-roboto-mono-nerd
  uar
  ugrep
  vlc
  waybar
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
