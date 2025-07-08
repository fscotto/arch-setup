#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

info "Installing Docker packages..."

PACKAGES=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

for pkg in "${PACKAGES[@]}"; do
  if yay -Qi "$pkg" &>/dev/null; then
    info "$pkg ✔ already installed"
  else
    info "Installing $pkg"
    yay -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1 && success "$pkg installed" || warn "Failed to install $pkg"
  fi
done
