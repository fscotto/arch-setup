#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-dev-tools-install.log}"
source "$SCRIPT_DIR/../lib/logging.sh"

info "Installing all development tools and additional apps..."

# Development packages (Arch/AUR)
DEV_PACKAGES=(
  argocd-bin
  base-devel
  clang
  clang-tools-extra
  cmake
  dwarves
  gcc
  gdb
  gh
  git
  git-delta
  git-extras
  glab-bin
  glow-bin
  helm
  hexyl
  hugo
  jmeter
  k9s
  kubectl
  lazydocker
  lazygit
  libasan
  luarocks
  make
  maven
  minikube-bin
  mise
  moar-bin
  ninja
  openshift-cli-bin
  operator-sdk-bin
  pkgconf
  python-black
  python-flake8
  python-ipython
  python-isort
  python-mypy
  python-pip
  python-pylint
  python-pytest
  python-virtualenv
  quarkus
  rustup
  spring-boot
  task
  yazi-bin
)

# Additional native Arch/AUR applications (including JetBrains IntelliJ Ultimate)
APP_PACKAGES=(
  code
  intellij-idea-ultimate-edition
  postman-bin
)

# Ensure yay installed
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

# Install Arch/AUR packages
for pkg in "${DEV_PACKAGES[@]}" "${APP_PACKAGES[@]}"; do
  if yay -Qi "$pkg" &>/dev/null; then
    info "$pkg ✔ already installed"
  else
    info "Installing $pkg"
    if yay -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
      success "$pkg installed"
    else
      warn "Failed to install $pkg"
    fi
  fi
done

# Configure Rust toolchain if rustup is installed or launch rustup-init
if command -v rustup &>/dev/null; then
  info "Configuring Rust toolchain"
  rustup default stable >>"$LOG_FILE" 2>&1 && success "Rust toolchain set to stable" || warn "Failed to set Rust toolchain"
else
  warn "rustup is not installed; launching rustup-init to configure Rust toolchain"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  if command -v rustup &>/dev/null; then
    info "Rustup installed, setting default toolchain"
    rustup default stable >>"$LOG_FILE" 2>&1 && success "Rust toolchain set to stable" || warn "Failed to set Rust toolchain"
  else
    warn "Rustup installation failed or was cancelled"
  fi
fi

# --- Mise configuration and plugin installation ---
info "Installing Mise core plugins and tools..."
plugins=(
  go
  java
  node
)
for plugin in "${plugins[@]}"; do
  info "Installing Mise plugin: $plugin"
  mise use -g -y "$plugin" >>"$LOG_FILE" 2>&1 || warn "Failed to install Mise plugin: $plugin"
done

info "Installing pinned versions of Java and Python..."
mise install -y java@temurin-17 >>"$LOG_FILE" 2>&1 || warn "Failed to install java@temurin-17"
mise install -y python@3.12 >>"$LOG_FILE" 2>&1 || warn "Failed to install python@3.12"

asdf_home="$HOME/.asdf"
if [ -d "$asdf_home" ]; then
  warn "Old ASDF directory found. Renaming to .asdf.old"
  mv "$asdf_home" "$asdf_home.old"
elif [ -e "$asdf_home" ]; then
  warn "Conflicting ASDF file found. Removing."
  rm -f "$asdf_home"
fi

success "Mise setup completed successfully."

# --- Visual Studio Code Extensions and Settings ---
info "Installing Visual Studio Code extensions..."

extensions=(
  budparr.language-hugo-vscode
  catppuccin.catppuccin-vsc
  catppuccin.catppuccin-vsc-icons
  catppuccin.catppuccin-vsc-pack
  christian-kohler.path-intellisense
  davidanson.vscode-markdownlint
  esbenp.prettier-vscode
  fill-labs.dependi
  formulahendry.auto-close-tag
  golang.go
  haskell.haskell
  mikestead.dotenv
  ms-azuretools.vscode-docker
  ms-vscode-remote.remote-containers
  ms-vscode.cmake-tools
  ms-vscode.cpptools
  ms-vscode.cpptools-extension-pack
  ms-vscode.cpptools-themes
  ms-vscode.makefile-tools
  pinage404.bash-extension-pack
  redhat.ansible
  redhat.vscode-tekton-pipelines
  redhat.vscode-xml
  redhat.vscode-yaml
  rusnasonov.vscode-hugo
  timonwong.shellcheck
  twxs.cmake
  xaver.clang-format
)

for ext in "${extensions[@]}"; do
  info "Installing extension: $ext"
  code --install-extension "$ext" 2>/dev/null || warn "Failed to install extension: $ext"
done

info "Writing Visual Studio Code user settings..."

mkdir -p ~/.config/Code/User

cat >~/.config/Code/User/settings.json <<'EOF'
{
    "workbench.startupEditor": "none",
    "workbench.iconTheme": "catppuccin-frappe",
    "workbench.colorTheme": "Catppuccin Frappé",
    "window.titleBarStyle": "custom",

    "editor.fontFamily": "'FiraCode Nerd Font'",
    "editor.fontSize": 20,

    // Terminal configurations
    "terminal.external.linuxExec": "kitty",
    "terminal.integrated.gpuAcceleration": "on",
    "terminal.integrated.defaultProfile.linux": "fish",
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.fontFamily": "'FiraCode Nerd Font'",
    "terminal.integrated.fontSize": 20,

    "redhat.telemetry.enabled": false,
    "[c]": {
        "editor.defaultFormatter": "xaver.clang-format"
    },
    "git.autofetch": true,
    "[javascript]": {
        "editor.defaultFormatter": "vscode.typescript-language-features"
    },
    "files.autoSave": "afterDelay"
}
EOF

success "Visual Studio Code setup completed successfully."

success "All development tools and applications installed."
