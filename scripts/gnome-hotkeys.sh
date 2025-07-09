#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# -------------------------------------------------------
# GNOME Hotkeys Configuration Script
#
# Sets custom GNOME hotkeys for workspace navigation,
# launcher shortcuts, and terminal launcher.
# -------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/functions.sh"

info "Setting GNOME hotkeys..."

# Navigation hotkeys: show desktop
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

# Move windows to workspace 1-10 with Super+Shift+number
for i in {1..9}; do
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Super><Shift>$i']"
done
# Workspace 10 is number 0 key
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "['<Super><Shift>0']"

# Switch to workspace 1-4 with Alt+Super+number
for i in {1..4}; do
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Alt><Super>$i']"
done

# Launcher hotkeys
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Shift><Alt>s']"
gsettings set org.gnome.settings-daemon.plugins.media-keys email "['<Super>e']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>f']"
gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>b']"

# Set custom shortcut to launch Kitty terminal with Super+Return
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Launch terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'

info "GNOME hotkeys configuration complete."
