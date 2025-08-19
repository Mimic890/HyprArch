#!/usr/bin/env bash
set -euo pipefail

# Colors
R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"

info(){ printf "${B}%s${E}\n" "$*"; }
ok(){   printf "${G}%s${E}\n" "$*"; }
warn(){ printf "${Y}%s${E}\n" "$*"; }
err(){  printf "${R}%s${E}\n" "$*" >&2; }

# Paths
CONFIG_SRC="$HOME/HyprArch/configs"
CUSTOM_HYPR_SRC="$HOME/HyprArch/customs/hypr"
CONFIG_DST="$HOME/.config"

# Check source directories
if [[ ! -d "$CONFIG_SRC" ]]; then
    err "Source directory not found: $CONFIG_SRC"
    exit 1
fi

if [[ ! -d "$CUSTOM_HYPR_SRC" ]]; then
    err "Source directory not found: $CUSTOM_HYPR_SRC"
    exit 1
fi

info "Checking for existing configs..."

# Remove existing conflicts
for item in "$CONFIG_SRC"/*; do
    name=$(basename "$item")
    if [[ -e "$CONFIG_DST/$name" ]]; then
        warn "Removing old: $CONFIG_DST/$name"
        rm -rf "$CONFIG_DST/$name"
    fi
done

# Copy new configs
info "Copying new configs..."
cp -r "$CONFIG_SRC"/* "$CONFIG_DST/"

# Replace hypr
if [[ -d "$CONFIG_DST/hypr" ]]; then
    warn "Removing old hypr config..."
    rm -rf "$CONFIG_DST/hypr"
fi

info "Copying custom hypr config..."
cp -r "$CUSTOM_HYPR_SRC" "$CONFIG_DST/"

# Reload Hyprland
info "Reloading Hyprland..."
if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload; then
        ok "Hyprland reloaded successfully"
    else
        warn "Failed to reload Hyprland"
    fi
else
    warn "hyprctl command not found"
fi

ok "Done"
exit 0