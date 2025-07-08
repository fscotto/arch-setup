#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"
source "$SCRIPT_DIR/lib/logging.sh"

info "🔧 Starting complete Arch Linux setup"

# Function to run a script with logging and error handling
run_script() {
  local script_path="$1"
  info "Running script: $script_path"
  if bash "$script_path"; then
    success "Completed: $script_path"
  else
    error "Error occurred while running $script_path"
    exit 1
  fi
}

# Check and install yay if needed
if ! command -v yay &>/dev/null; then
  info "yay not found, installing..."
  sudo pacman -S --needed --noconfirm git base-devel >>"$LOG_FILE" 2>&1
  git clone https://aur.archlinux.org/yay.git /tmp/yay >>"$LOG_FILE" 2>&1
  (cd /tmp/yay && makepkg -si --noconfirm >>"$LOG_FILE" 2>&1)
  rm -rf /tmp/yay
  success "yay installed"
else
  success "yay already installed"
fi

# List of scripts to run in order
SCRIPTS=(
  "$SCRIPT_DIR/scripts/app-system.sh"
  "$SCRIPT_DIR/scripts/app-multimedia.sh"
  "$SCRIPT_DIR/scripts/devtools.sh"
  "$SCRIPT_DIR/scripts/app-docker.sh"
  "$SCRIPT_DIR/scripts/dotfiles.sh"
  "$SCRIPT_DIR/scripts/set-gnome-extensions.sh"
  "$SCRIPT_DIR/scripts/set-gnome-hotkeys.sh"
  "$SCRIPT_DIR/scripts/set-gnome-preferences.sh"
  "$SCRIPT_DIR/scripts/set-openssl-legacy.sh"
  "$SCRIPT_DIR/scripts/tpm2.sh"
  "$SCRIPT_DIR/scripts/setup-plymouth.sh"
  "$SCRIPT_DIR/scripts/setup-secureboot.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" && -x "$script" ]]; then
    run_script "$script"
  else
    warn "Script missing or not executable: $script"
  fi
done

success "✅ Arch Linux setup completed successfully"
