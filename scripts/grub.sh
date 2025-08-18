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

info "Configuring GRUB..."

GRUB_CONF_SRC="$HOME/HyprArch/customs/grub/grub"
GRUB_CONF_DEST="/etc/default/grub"
GRUB_THEME_SRC="$HOME/HyprArch/customs/grub/hypr"
GRUB_THEME_DEST="/usr/share/grub/themes/"

if [ -f "$GRUB_CONF_SRC" ]; then
    info "Copying GRUB config..."
    sudo cp "$GRUB_CONF_SRC" "$GRUB_CONF_DEST"
    ok "GRUB config copied successfully"
else
    err "File not found:${E} $GRUB_CONF_SRC"
    err "GRUB configuration failed. Aborting."
    exit 1
fi

if [ -d "$GRUB_THEME_SRC" ]; then
    info "Copying GRUB theme..."
    sudo cp -r "$GRUB_THEME_SRC" "$GRUB_THEME_DEST"
    ok "GRUB theme copied successfully"
else
    err "Theme folder not found:${E} $GRUB_THEME_SRC"
    err "GRUB configuration failed. Aborting."
    exit 1
fi

info "Generating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg
ok "GRUB configuration generated successfully"
exit 0
