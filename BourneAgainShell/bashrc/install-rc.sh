#!/bin/bash

# install-rc.sh: Automate bashrc installation as per README.md instructions

set -e

# Define variables
BASHRC_SOURCE="$(pwd)/bashrc"
BASHRC_TARGET="$HOME/.bashrc"
BACKUP="$HOME/.bashrc.backup.$(date +%Y%m%d%H%M%S)"

# Backup existing .bashrc if it exists
if [ -f "$BASHRC_TARGET" ]; then
  echo "Backing up existing .bashrc to $BACKUP"
  cp "$BASHRC_TARGET" "$BACKUP"
fi

# Copy new bashrc
echo "Installing new .bashrc from $BASHRC_SOURCE"
cp "$BASHRC_SOURCE" "$BASHRC_TARGET"

echo "Installation complete. Please restart your terminal or run 'source ~/.bashrc' to apply changes."