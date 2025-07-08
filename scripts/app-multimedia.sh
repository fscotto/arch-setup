#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

info "Installing multimedia packages and codecs..."

PACKAGES=(
  intel-media-driver
  libavcodec-freeworld # only if available via AUR
  pipewire-codec-aptx
  ffmpegthumbnailer
)

for pkg in "${PACKAGES[@]}"; do
  if yay -Qi "$pkg" &>/dev/null; then
    info "$pkg ✔ already installed"
  else
    info "Installing $pkg"
    yay -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1 || warn "$pkg not available or installation failed"
    [[ $? -eq 0 ]] && success "$pkg installed"
  fi
done
