#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

# Elevate privileges if not root
if [[ $EUID -ne 0 ]]; then
  info "Elevating privileges with sudo..."
  sudo bash "$0" "$@"
  exit $?
fi

find_luks_devices() {
  mapfile -t devices < <(blkid -t TYPE=crypto_LUKS -o device)
  echo "${devices[@]}"
}

choose_luks_device() {
  local devices=("$@")

  if ((${#devices[@]} == 0)); then
    echo ""
    return 1
  elif ((${#devices[@]} == 1)); then
    echo "${devices[0]}"
    return 0
  else
    info "Multiple LUKS devices found:"
    for i in "${!devices[@]}"; do
      info "  $((i + 1))) ${devices[i]}"
    done
    while true; do
      read -rp "Choose the device number to use: " choice
      if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && ((choice >= 1 && choice <= ${#devices[@]})); then
        echo "${devices[$((choice - 1))]}"
        return 0
      else
        warn "Invalid choice, please try again."
      fi
    done
  fi
}

tpm_device_exists() {
  [[ -d /sys/class/tpm ]] || [[ -c /dev/tpm0 ]]
}

configure_mkinitcpio() {
  info "Detected mkinitcpio system (Arch Linux)"
  if ! grep -q "tpm2" /etc/mkinitcpio.conf; then
    info "Adding 'tpm2' hook to mkinitcpio.conf"
    if grep -q 'HOOKS=.*encrypt' /etc/mkinitcpio.conf; then
      sed -i 's/\(HOOKS=.*\)encrypt/\1tpm2 encrypt/' /etc/mkinitcpio.conf
    else
      sed -i 's/\(HOOKS=.*block\)/\1 tpm2/' /etc/mkinitcpio.conf
    fi
    info "Regenerating initramfs"
    mkinitcpio -P >>"$LOG_FILE" 2>&1 || warn "mkinitcpio command failed"
    success "Updated initramfs with 'tpm2' hook"
  else
    warn "'tpm2' hook already present in mkinitcpio.conf"
  fi
}

configure_dracut() {
  info "Detected dracut system (EndeavourOS)"
  local dracut_conf="/etc/dracut.conf"
  local dracut_modules="/usr/lib/dracut/modules.d"

  # Add tpm2 module to dracut config (if not already present)
  if ! grep -q "tpm2" "$dracut_conf" 2>/dev/null; then
    info "Adding 'tpm2' to dracut modules in $dracut_conf"
    echo 'add_dracutmodules+=" tpm2 "' >>"$dracut_conf"
  else
    warn "'tpm2' module already enabled in dracut config"
  fi

  info "Regenerating initramfs with dracut"
  # Regenerate all kernels' initramfs images
  dracut --force --kver "$(uname -r)" >>"$LOG_FILE" 2>&1 || warn "dracut command failed"
  success "Updated initramfs with 'tpm2' module"
}

configure_tpm_module() {
  mapfile -t luks_devices < <(find_luks_devices)

  luks2_device=$(choose_luks_device "${luks_devices[@]}") || {
    error "Unable to find or select LUKS device."
    exit 1
  }

  info "Configuring TPM2 to unlock LUKS partition: $luks2_device"

  if [[ -f /etc/mkinitcpio.conf ]]; then
    configure_mkinitcpio
  elif [[ -f /etc/dracut.conf || -d /usr/lib/dracut/modules.d ]]; then
    configure_dracut
  else
    error "Could not detect initramfs tool (mkinitcpio or dracut). Exiting."
    exit 1
  fi

  info "Enrolling TPM2 with systemd-cryptenroll"
  systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs "7" "$luks2_device" >>"$LOG_FILE" 2>&1 || {
    error "Failed to enroll TPM2 with systemd-cryptenroll"
    exit 1
  }

  info "Backing up /etc/crypttab to /etc/crypttab.bak"
  cp /etc/crypttab /etc/crypttab.bak

  if ! grep -q "tpm2-device=auto" /etc/crypttab; then
    info "Appending TPM2 options to /etc/crypttab"
    sed -i '/^[^#]/ s/$/ tpm2-device=auto,tpm2-pcrs=0+1+2+3+4+5+7+9/' /etc/crypttab
  else
    warn "TPM2 options already present in /etc/crypttab"
  fi

  success "TPM2 configuration completed."
}

if tpm_device_exists; then
  info "TPM device detected"
  while true; do
    read -r -p "Do you want to configure the TPM chip? (Y/N): " answer
    case $answer in
    [Yy]*)
      configure_tpm_module
      break
      ;;
    [Nn]*)
      info "TPM configuration skipped."
      break
      ;;
    *)
      warn "Please answer Y or N."
      ;;
    esac
  done
else
  error "TPM device not found on this system"
fi
