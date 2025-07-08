#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

# Relaunch script as root if not running as root
if [[ $EUID -ne 0 ]]; then
  info "Script requires root privileges, relaunching with sudo..."
  exec sudo "$0" "$@"
fi

info "Starting Secure Boot setup with sbctl..."

info "Installing sbctl and sbsigntools packages..."
pacman -Sy --noconfirm sbctl sbsigntools

info "Checking Secure Boot status..."
sbctl status

info "Creating sbctl keys..."
sbctl create-keys

info "Enrolling keys including Microsoft keys (for dual boot compatibility)..."
sbctl enroll-keys -m

info "Signing kernel and bootloader..."
KERNEL_PATH="/boot/vmlinuz-linux"
BOOTLOADER_PATH="/efi/EFI/refind/refind_x64.efi"

if [[ ! -f "$KERNEL_PATH" ]]; then
  warn "Kernel not found at $KERNEL_PATH. Please check and sign manually."
else
  sbctl sign -s "$KERNEL_PATH"
fi

if [[ ! -f "$BOOTLOADER_PATH" ]]; then
  warn "Bootloader not found at $BOOTLOADER_PATH. Please check and sign manually."
else
  sbctl sign -s "$BOOTLOADER_PATH"
fi

info "Verifying signatures..."
sbctl verify

success "Secure Boot setup completed. Please reboot and enable Secure Boot in BIOS/UEFI settings."

