#!/bin/bash
set -e

B="\e[34m"
G="\e[32m"
Y="\e[33m"
R="\e[31m"
E="\e[0m"

info(){  echo -e "${B}$*"; }
ok(){    echo -e "${G}$*"; }
warn(){  echo -e "${Y}$*"; }
err(){   echo -e "${R}$*" >&2; }

FISH_PATH="/usr/bin/fish"
FISH_CONFIG_SRC="$HOME/HyprArch/customs/fish"
FISH_CONFIG_DEST="$HOME/.config/fish"

if ! command -v fish >/dev/null 2>&1; then
    info "Installing fish shell..."
    if ! sudo pacman -S --noconfirm fish; then
        err "Failed to install fish shell."
        exit 1
    fi
else
    ok "Fish shell is already installed."
fi

if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    ok "Added fish to /etc/shells"
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    if chsh -s "$FISH_PATH"; then
        echo -e "Fish set as the default shell."
    else
        err "Failed to set fish as the default shell."
        exit 1
    fi
else
    ok "Fish is already the default shell."
fi

info "Copying fish configuration..."
mkdir -p "$HOME/.config"

if [ -d "$FISH_CONFIG_SRC" ]; then
    rm -rf "$FISH_CONFIG_DEST"
    if cp -r "$FISH_CONFIG_SRC" "$HOME/.config/"; then
        ok "Fish configuration copied successfully."
    else
        err "Failed to copy fish configuration."
        exit 1
    fi
else
    err "Fish config directory not found: $FISH_CONFIG_SRC"
    exit 1
fi

ok "Fish shell installed and configured successfully."
exit 0
