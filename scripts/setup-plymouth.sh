#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Auto elevate to root if needed
if [[ $EUID -ne 0 ]]; then
  info "Elevating privileges with sudo..."
  sudo bash "$0" "$@"
  exit $?
fi

PLYMOUTH_THEME="bgrt"

info "Installing and configuring Plymouth theme..."

# Function to detect initramfs tool: mkinitcpio or dracut
detect_initramfs_tool() {
  if [[ -f /etc/mkinitcpio.conf ]]; then
    echo "mkinitcpio"
  elif [[ -f /etc/dracut.conf || -d /usr/lib/dracut/modules.d ]]; then
    echo "dracut"
  else
    echo ""
  fi
}

initramfs_tool=$(detect_initramfs_tool)
if [[ -z "$initramfs_tool" ]]; then
  error "Could not detect initramfs tool (mkinitcpio or dracut). Exiting."
  exit 1
fi

# Install Plymouth if missing
if yay -Qi plymouth &>/dev/null; then
  info "Plymouth is already installed"
else
  info "Installing Plymouth"
  yay -S --noconfirm plymouth >>"$LOG_FILE" 2>&1 && success "Plymouth installed" || {
    error "Failed to install Plymouth"
    exit 1
  }
fi

# Install Plymouth theme if missing
if yay -Qi "plymouth-theme-$PLYMOUTH_THEME" &>/dev/null; then
  info "Plymouth theme '$PLYMOUTH_THEME' is already installed"
else
  info "Installing Plymouth theme '$PLYMOUTH_THEME'"
  yay -S --noconfirm "plymouth-theme-$PLYMOUTH_THEME" >>"$LOG_FILE" 2>&1 && success "Theme '$PLYMOUTH_THEME' installed" || warn "Failed to install theme '$PLYMOUTH_THEME'"
fi

# Set Plymouth theme in configuration file
if grep -q "^Theme=" /etc/plymouth/plymouthd.conf 2>/dev/null; then
  sed -i "s/^Theme=.*/Theme=$PLYMOUTH_THEME/" /etc/plymouth/plymouthd.conf
else
  echo "Theme=$PLYMOUTH_THEME" >>/etc/plymouth/plymouthd.conf
fi
success "Set Plymouth theme to '$PLYMOUTH_THEME'"

if [[ "$initramfs_tool" == "mkinitcpio" ]]; then
  # Add plymouth hook to mkinitcpio.conf if not present
  if ! grep -q plymouth /etc/mkinitcpio.conf; then
    info "Adding 'plymouth' hook to mkinitcpio.conf"
    sudo sed -i 's/^\(HOOKS=.*\)/\1 plymouth/' /etc/mkinitcpio.conf
    info "Regenerating initramfs with mkinitcpio"
    mkinitcpio -P >>"$LOG_FILE" 2>&1 && success "Updated mkinitcpio with 'plymouth' hook" || warn "Failed to regenerate initramfs"
  else
    info "'plymouth' hook already present in mkinitcpio.conf"
  fi
elif [[ "$initramfs_tool" == "dracut" ]]; then
  # Add plymouth module to dracut config if not present
  if ! grep -q "plymouth" /etc/dracut.conf 2>/dev/null; then
    info "Adding 'plymouth' to dracut modules in /etc/dracut.conf"
    echo 'add_dracutmodules+=" plymouth "' >>/etc/dracut.conf
  else
    info "'plymouth' module already enabled in dracut config"
  fi
  info "Regenerating initramfs with dracut"
  dracut --force --kver "$(uname -r)" >>"$LOG_FILE" 2>&1 && success "Updated dracut initramfs with 'plymouth' module" || warn "Failed to regenerate dracut initramfs"
fi

success "Plymouth setup completed"
