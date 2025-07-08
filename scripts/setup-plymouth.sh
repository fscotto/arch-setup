#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

info "Installing and configuring Plymouth theme..."

# Plymouth theme to install (change as needed)
PLYMOUTH_THEME="bgrt"

# Install Plymouth
if yay -Qi plymouth &>/dev/null; then
  info "Plymouth is already installed"
else
  info "Installing Plymouth"
  yay -S --noconfirm plymouth >>"$LOG_FILE" 2>&1 && success "Plymouth installed" || {
    error "Failed to install Plymouth"
    exit 1
  }
fi

# Install Plymouth theme
if yay -Qi "plymouth-theme-$PLYMOUTH_THEME" &>/dev/null; then
  info "Plymouth theme '$PLYMOUTH_THEME' is already installed"
else
  info "Installing Plymouth theme '$PLYMOUTH_THEME'"
  yay -S --noconfirm "plymouth-theme-$PLYMOUTH_THEME" >>"$LOG_FILE" 2>&1 && success "Theme '$PLYMOUTH_THEME' installed" || warn "Failed to install theme '$PLYMOUTH_THEME'"
fi

# Set Plymouth theme in configuration file
if grep -q "^Theme=" /etc/plymouth/plymouthd.conf 2>/dev/null; then
  sudo sed -i "s/^Theme=.*/Theme=$PLYMOUTH_THEME/" /etc/plymouth/plymouthd.conf
else
  echo "Theme=$PLYMOUTH_THEME" | sudo tee -a /etc/plymouth/plymouthd.conf >/dev/null
fi
success "Set Plymouth theme to '$PLYMOUTH_THEME'"

# Add plymouth hook to mkinitcpio if not already present
if ! grep -q plymouth /etc/mkinitcpio.conf; then
  info "Adding 'plymouth' hook to mkinitcpio.conf"
  sudo sed -i 's/^\(HOOKS=.*\)/\1 plymouth/' /etc/mkinitcpio.conf
  sudo mkinitcpio -P >>"$LOG_FILE" 2>&1
  success "Updated mkinitcpio with 'plymouth' hook"
else
  info "'plymouth' hook already present in mkinitcpio.conf"
fi

success "Plymouth setup completed"
