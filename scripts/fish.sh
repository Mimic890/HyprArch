#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

FISH_PATH="/usr/bin/fish"
FISH_CONFIG_SRC="$HOME/HyprArch/customs/fish"
FISH_CONFIG_DEST="$HOME/.config/fish"

if ! command -v fish >/dev/null 2>&1; then
    echo -e "${B}Installing fish shell...${E}"
    if ! sudo pacman -S --noconfirm fish; then
        echo -e "${R}Failed to install fish shell.${E}"
        exit 1
    fi
else
    echo -e "${G}Fish shell is already installed.${E}"
fi

if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    echo -e "${G}Added fish to /etc/shells${E}"
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    if chsh -s "$FISH_PATH"; then
        echo -e "Fish set as the default shell.${E}"
    else
        echo -e "${R}Failed to set fish as the default shell.${E}"
        exit 1
    fi
else
    echo -e "${G}Fish is already the default shell.${E}"
fi

echo -e "${B}Copying fish configuration...${E}"
mkdir -p "$HOME/.config"

if [ -d "$FISH_CONFIG_SRC" ]; then
    rm -rf "$FISH_CONFIG_DEST"
    if cp -r "$FISH_CONFIG_SRC" "$HOME/.config/"; then
        echo -e "${G}Fish configuration copied successfully.${E}"
    else
        echo -e "${R}Failed to copy fish configuration.${E}"
        exit 1
    fi
else
    echo -e "${R}Fish config directory not found: $FISH_CONFIG_SRC${E}"
    exit 1
fi

echo -e "${G}Fish shell installed and configured successfully.${E}"
exit 0
