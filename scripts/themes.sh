#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

echo -e "${B}
##-------------------------------##
## Installing GTK themes & icons ##
##-------------------------------##${E}"

sudo pacman -S --noconfirm breeze-gtk gtk-engine-murrine gtk-engines || {
    echo -e "${R}Failed to install GTK dependencies${E}"
    exit 1
}

echo -e "${B}Installing Fluent Icon Theme...${E}"
if [ ! -d "$HOME/.icons/Fluent" ]; then
    git clone https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icons
    if /tmp/fluent-icons/install.sh -n standart; then
        echo -e "${G}Fluent Icon Theme installed${E}"
    else
        echo -e "${R}Fluent Icon Theme installation failed, cleaning up...${E}"
        rm -rf /tmp/fluent-icons
        exit 1
    fi
    rm -rf /tmp/fluent-icons
else
    echo -e "${Y}Fluent Icon Theme already installed${E}"
fi

gsettings set org.gnome.desktop.interface gtk-theme "Breeze-Dark" || echo -e "${Y}Could not set GTK theme${E}"
gsettings set org.gnome.desktop.interface icon-theme "Fluent-dark" || echo -e "${Y}Could not set icon theme${E}"

echo -e "${G}GTK themes & icons setup completed${E}"
