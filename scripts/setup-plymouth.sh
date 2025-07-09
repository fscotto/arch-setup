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

# Ensure 'splash' and 'quiet' are present in GRUB_CMDLINE_LINUX_DEFAULT
if [[ -f /etc/default/grub ]]; then
  line=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub)

  # Estrai il contenuto tra virgolette (singole o doppie)
  current_opts=$(echo "$line" | sed -E 's/^GRUB_CMDLINE_LINUX_DEFAULT=.(.*).$/\1/')

  # Aggiungi quiet e splash se mancano
  new_opts="$current_opts"
  [[ "$new_opts" != *quiet* ]] && new_opts="$new_opts quiet"
  [[ "$new_opts" != *splash* ]] && new_opts="$new_opts splash"

  # Ripulisci spazi multipli
  new_opts=$(echo "$new_opts" | xargs)

  if [[ "$current_opts" != "$new_opts" ]]; then
    info "Adding 'quiet' and/or 'splash' to GRUB_CMDLINE_LINUX_DEFAULT"
    sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${new_opts}\"|" /etc/default/grub

    grub-mkconfig -o /boot/grub/grub.cfg >>"$LOG_FILE" 2>&1 &&
      success "Updated GRUB configuration with: $new_opts" ||
      warn "Failed to update GRUB config"
  else
    info "'splash' and 'quiet' already present in GRUB_CMDLINE_LINUX_DEFAULT"
  fi
fi

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
  # Ensure /etc/dracut.conf.d exists
  mkdir -p /etc/dracut.conf.d

  # Enable plymouth module via drop-in conf if not already enabled
  if ! grep -q 'add_dracutmodules.*plymouth' /etc/dracut.conf.d/plymouth.conf 2>/dev/null; then
    info "Creating /etc/dracut.conf.d/plymouth.conf to enable plymouth module"
    echo 'add_dracutmodules+=" plymouth "' >/etc/dracut.conf.d/plymouth.conf
  else
    info "Plymouth module already enabled in /etc/dracut.conf.d/plymouth.conf"
  fi

  # Create conf to omit uefi module if not already present
  if [[ ! -f /etc/dracut.conf.d/no-uefi.conf ]]; then
    info "Creating /etc/dracut.conf.d/no-uefi.conf to omit uefi module"
    echo 'omit_dracutmodules+=" uefi "' >/etc/dracut.conf.d/no-uefi.conf
  else
    info "/etc/dracut.conf.d/no-uefi.conf already exists"
  fi

  # Check if /boot/efi is mounted and create EFI dir if missing
  if mountpoint -q /boot/efi; then
    if [[ ! -d /boot/efi/EFI/Linux ]]; then
      info "Creating missing directory /boot/efi/EFI/Linux required by dracut"
      mkdir -p /boot/efi/EFI/Linux
    fi
  else
    warn "/boot/efi not mounted; dracut might fail if --uefi is used"
  fi

  info "Regenerating initramfs with dracut"
  dracut --force --kver "$(uname -r)" >>"$LOG_FILE" 2>&1 &&
    success "Updated dracut initramfs with 'plymouth' module" ||
    warn "Failed to regenerate dracut initramfs"
fi

success "Plymouth setup completed"
