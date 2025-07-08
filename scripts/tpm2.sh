#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

# Find all LUKS encrypted devices on the system
find_luks_devices() {
  mapfile -t devices < <(blkid -t TYPE=crypto_LUKS -o device)
  echo "${devices[@]}"
}

# If multiple LUKS devices are found, ask the user to choose one
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

# Configure TPM2 to unlock the LUKS partition
configure_tpm_module() {
  mapfile -t luks_devices < <(find_luks_devices)

  luks2_device=$(choose_luks_device "${luks_devices[@]}") || {
    error "Unable to find or select LUKS device."
    exit 1
  }

  info "Configuring TPM2 to unlock LUKS partition: $luks2_device"

  # Add 'tpm2' hook to mkinitcpio if not present
  if ! grep -q "tpm2" /etc/mkinitcpio.conf; then
    info "Adding 'tpm2' hook to mkinitcpio"
    sudo sed -i 's/^\(HOOKS=.*\)encrypt\(.*\)/\1encrypt tpm2\2/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P >>"$LOG_FILE" 2>&1
    success "Updated initramfs with 'tpm2' hook"
  else
    warn "'tpm2' hook already present in mkinitcpio.conf"
  fi

  info "Running systemd-cryptenroll for TPM2 device"
  sudo systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs "7" "$luks2_device" >>"$LOG_FILE" 2>&1

  info "Backing up /etc/crypttab"
  sudo cp /etc/crypttab /etc/crypttab.bak

  info "Appending TPM2 options to /etc/crypttab"
  sudo sed -i 's/$/ tpm2-device=auto,tpm2-pcrs=0+1+2+3+4+5+7+9/' /etc/crypttab

  success "TPM2 configuration completed."
}

# Check if TPM device exists
if ls -d /sys/kernel/security/tpm* 1>/dev/null 2>&1; then
  info "TPM device available"
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
    *) warn "Please answer Y or N." ;;
    esac
  done
else
  error "TPM device not found"
fi
