#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# -------------------------------------------------------
# GNOME Extensions Installer and Configurator
#
# Installs GNOME Extensions using gnome-extensions-cli (gext)
# Copies extension schemas to system directory and compiles schemas.
# Configures specific GNOME extension settings via gsettings.
# -------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"

USER_EXT="$HOME/.local/share/gnome-shell/extensions"
SYSTEM_EXT="/usr/share/glib-2.0/schemas"

info "Installing GNOME Extension CLI tool..."
pipx install gnome-extensions-cli --system-site-packages

# Add $HOME/.local/bin to PATH if not already present
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  info "Added $HOME/.local/bin to PATH"
else
  info "$HOME/.local/bin already in PATH"
fi

info "Installing GNOME Extensions..."
extensions=(
  "clipboard-history@alexsaveau.dev"
  "drive-menu@gnome-shell-extensions.gcampax.github.com"
  "gnome-ui-tune@itstime.tech"
  "caffeine@patapon.info"
  "bluetooth-quick-connect@bjarosze.gmail.com"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "no-overview@fthx"
  "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
  "appindicatorsupport@rgcjonas.gmail.com"
  "blur-my-shell@aunetx"
  "Vitals@CoreCoding.com"
)

for ext in "${extensions[@]}"; do
  info "Installing extension: $ext"
  gext install "$ext"
done

info "Copying extension schemas to system directory..."
declare -a schemas=(
  "bluetooth-quick-connect@bjarosze.gmail.com"
  "caffeine@patapon.info"
  "clipboard-history@alexsaveau.dev"
  "gnome-ui-tune@itstime.tech"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
  "blur-my-shell@aunetx"
  "Vitals@CoreCoding.com"
)

for schema in "${schemas[@]}"; do
  src="${USER_EXT}/${schema}/schemas/org.gnome.shell.extensions.${schema}.gschema.xml"
  if [[ -f "$src" ]]; then
    info "Copying schema $src to $SYSTEM_EXT"
    sudo cp "$src" "$SYSTEM_EXT"
  else
    warn "Schema file for $schema not found at $src"
  fi
done

info "Compiling GSettings schemas..."
sudo glib-compile-schemas "$SYSTEM_EXT"

info "Configuring GNOME Extensions settings..."

# Caffeine
gsettings set org.gnome.shell.extensions.caffeine inhibit-apps "['org.videolan.VLC.desktop']"

# Bluetooth Quick Connect
gsettings set org.gnome.shell.extensions.bluetooth-quick-connect show-battery-value-on true

# Status Area Horizontal Spacing
gsettings set org.gnome.shell.extensions.status-area-horizontal-spacing hpadding 5

# Blur My Shell
gsettings set org.gnome.shell.extensions.blur-my-shell.overview blur false
gsettings set org.gnome.shell.extensions.blur-my-shell.applications blur false
gsettings set org.gnome.shell.extensions.blur-my-shell pipelines "{'pipeline_default': {'name': <'Default'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_67814402149198'>, 'params': <{'unscaled_radius': <0>}>}>]>}, 'pipeline_default_rounded': {'name': <'Default rounded'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000001'>, 'params': <{'radius': <30>, 'brightness': <0.6>}>}>, <{'type': <'corner'>, 'id': <'effect_000000000002'>, 'params': <{'radius': <24>}>}>]>}}"

# Vitals
gsettings set org.gnome.shell.extensions.vitals hot-sensors "['__temperature_avg__', '_memory_allocated_', '_system_uptime_']"

info "GNOME Extensions installation and configuration completed."
