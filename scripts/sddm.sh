#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"
#
info(){ printf "${B}%s\n" "$*"; }
ok(){   printf "${G}%s\n" "$*"; }
warn(){ printf "${Y}%s\n" "$*"; }
err(){  printf "${R}%s\n" "$*" >&2; }

info "Configuring SDDM..."

THEME_SRC="$HOME/HyprArch/customs/SDDM/hyprarch-sddm"
THEME_DEST="/usr/share/sddm/themes/"
CONF_SRC="$HOME/HyprArch/customs/SDDM/sddm.conf"
CONF_DEST="/etc/sddm.conf"

if [ -d "$THEME_SRC" ]; then
    info "Copying theme..."
    sudo cp -r "$THEME_SRC" "$THEME_DEST"
    ok "SDDM theme copied successfully"
else
    err "Theme folder not found: $THEME_SRC"
    err "SDDM configuration failed. Aborting."
    exit 1
fi
if [ -f "$CONF_SRC" ]; then
    info "Copying sddm.conf..."
    sudo cp "$CONF_SRC" "$CONF_DEST"
    ok "sddm.conf copied successfully"
else
    err "Config file not found: $CONF_SRC"
    err "SDDM configuration failed. Aborting."
    exit 1
fi

exit 0
