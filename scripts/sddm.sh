#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

echo -e "${B}Configuring SDDM...${E}"

THEME_SRC="$HOME/HyprArch/customs/SDDM/hyprarch-sddm"
THEME_DEST="/usr/share/sddm/themes/"
CONF_SRC="$HOME/HyprArch/customs/SDDM/sddm.conf"
CONF_DEST="/etc/sddm.conf"

if [ -d "$THEME_SRC" ]; then
    echo -e "${B}Copying theme...${E}"
    sudo cp -r "$THEME_SRC" "$THEME_DEST"
    echo -e "${G}SDDM theme copied successfully${E}"
else
    echo -e "${R}Theme folder not found:${E} $THEME_SRC"
    echo -e "${R}SDDM configuration failed. Aborting.${E}"
    exit 1
fi

if [ -f "$CONF_SRC" ]; then
    echo -e "${B}Copying sddm.conf...${E}"
    sudo cp "$CONF_SRC" "$CONF_DEST"
    echo -e "${G}sddm.conf copied successfully${E}"
else
    echo -e "${R}Config file not found:${E} $CONF_SRC"
    echo -e "${R}SDDM configuration failed. Aborting.${E}"
    exit 1
fi

exit 0
