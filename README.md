# Arch Linux Workstation Setup Scripts

This repository contains a collection of Bash scripts to automate the installation and configuration of an Arch Linux development workstation.

---

## Features

- Automated installation of essential development tools and applications via `pacman` and `yay` (AUR helper)
- Management of dotfiles using GNU Stow with selective package application
- Configuration of TPM2 for disk unlocking with systemd-cryptenroll
- Plymouth boot splash setup with customizable themes (BGRT default)
- OpenSSL legacy renegotiation enabling for legacy software compatibility
- Visual Studio Code installation with curated extensions
- Installation of popular Nerd Fonts from Arch repositories
- Centralized logging system to track script execution and errors

---

## Prerequisites

- A running Arch Linux system with sudo privileges
- Internet connection
- `git` installed

---

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/fscotto/arch-workstation-setup.git
   cd arch-workstation-setup
   ```

2. **Run the main setup script**

   The main script will sequentially execute all setup scripts.

   ```bash
   ./install.sh
   ```

3. **Run individual scripts**

   You can also run any script individually, for example:

   ```bash
   ./scripts/devtools.sh
   ./scripts/dotfiles.sh
   ./scripts/openssl-legacy.sh
   ./scripts/setup-tpm2.sh
   ./scripts/setup-plymouth.sh
   ```

---

## Dotfiles

Dotfiles are managed using GNU Stow and applied selectively based on a predefined package list to avoid conflicts.

---

## Logging

All scripts use a centralized logging mechanism defined in `lib/logging.sh`. Logs are saved and useful for debugging.

---

## Contributing

Feel free to fork, submit issues, or open pull requests to improve this setup.

---

## License

This project is licensed under the MIT License.

---

## Author

Fabio Scotto di Santolo
