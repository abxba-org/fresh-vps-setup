#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt update

echo "Installing terminal tools..."

sudo apt install -y
    exa
    fd-find
    zoxide
    neofetch
    bat
    fzf
    ripgrep
    curl

echo "Installing Atuin..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

echo "Creating command aliases..."

# Ubuntu/Debian command name fixes
mkdir -p ~/.local/bin

ln -sf /usr/bin/fdfind ~/.local/bin/fd
ln -sf /usr/bin/batcat ~/.local/bin/bat

echo ""
echo "Installation completed!"
echo "Restart your terminal or run:"
echo "source ~/.bashrc"
echo ""
echo "Installed tools:"
echo "exa, fd, zoxide, neofetch, atuin, bat, fzf, ripgrep"
