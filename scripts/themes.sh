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

info "
###################################
## Installing GTK themes & icons ##
###################################"

sudo pacman -S --noconfirm breeze-gtk gtk-engine-murrine gtk-engines || {
    err "Failed to install GTK dependencies"
    exit 1
}

info "Installing Fluent Icon Theme..."
if [ ! -d "$HOME/.icons/Fluent" ]; then
    git clone https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icons
    if /tmp/fluent-icons/install.sh -a; then
        ok "Fluent Icon Theme installed"
    else
        err "Fluent Icon Theme installation failed, cleaning up..."
        rm -rf /tmp/fluent-icons
        exit 1
    fi
    rm -rf /tmp/fluent-icons
else
    warn "Fluent Icon Theme already installed"
fi

gsettings set org.gnome.desktop.interface gtk-theme "Breeze-Dark" || warn "Could not set GTK theme"
gsettings set org.gnome.desktop.interface icon-theme "Fluent-dark" || warn "Could not set icon theme"

ok "GTK themes & icons setup completed"

exit 0