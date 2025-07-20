#!/bin/bash

set -e

# Auto-elevate with sudo if not root
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges. Re-running with sudo..."
  exec sudo "$0" "$@"
fi

# Load current os-release
source /etc/os-release

# Check if system is clean Arch Linux
if [[ "$ID" != "arch" ]]; then
  echo "Detected distribution ID: $ID"
  echo "This script only supports clean Arch Linux systems."
  exit 1
fi

# First confirmation
read -p "Are you running clean Arch Linux? (y/N): " confirm1
if [[ "$confirm1" != "y" && "$confirm1" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# Second confirmation
read -p "Are you sure you want to replace /etc/os-release with HyprArch version? (y/N): " confirm2
if [[ "$confirm2" != "y" && "$confirm2" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# Backup original file
cp /etc/os-release /etc/os-release.bak
echo "Backup created at /etc/os-release.bak"

# Get original file permissions and ownership
ORIG_PERMS=$(stat -c "%a" /etc/os-release)
ORIG_OWNER=$(stat -c "%u" /etc/os-release)
ORIG_GROUP=$(stat -c "%g" /etc/os-release)

# Remove old file
rm /etc/os-release

# Copy new file from user's custom path
cp ~/HyprArch/customs/os-release /etc/os-release

# Restore original permissions and ownership
chmod "$ORIG_PERMS" /etc/os-release
chown "$ORIG_OWNER":"$ORIG_GROUP" /etc/os-release

echo "/etc/os-release has been successfully replaced with the custom HyprArch version."
