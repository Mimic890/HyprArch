#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

echo -e "${B}>>> Configuring GRUB...${E}"

GRUB_CONF_SRC="$HOME/HyprArch/customs/grub/grub"
GRUB_CONF_DEST="/etc/default/grub"
GRUB_THEME_SRC="$HOME/HyprArch/customs/grub/hypr"
GRUB_THEME_DEST="/usr/share/grub/themes/"

if [ -f "$GRUB_CONF_SRC" ]; then
    echo -e "${B}Copying GRUB config...${E}"
    sudo cp "$GRUB_CONF_SRC" "$GRUB_CONF_DEST"
    echo -e "${G}✓ GRUB config copied successfully${E}"
else
    echo -e "${R}✗ File not found:${E} $GRUB_CONF_SRC"
    echo -e "${R}GRUB configuration failed. Aborting.${E}"
    exit 1
fi

if [ -d "$GRUB_THEME_SRC" ]; then
    echo -e "${B}Copying GRUB theme...${E}"
    sudo cp -r "$GRUB_THEME_SRC" "$GRUB_THEME_DEST"
    echo -e "${G}GRUB theme copied successfully${E}"
else
    echo -e "${R}Theme folder not found:${E} $GRUB_THEME_SRC"
    echo -e "${R}GRUB configuration failed. Aborting.${E}"
    exit 1
fi

echo -e "${B}Generating GRUB configuration...${E}"
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo -e "${G}GRUB configuration generated successfully${E}"
exit 0
