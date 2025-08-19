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

GRUB_FILE="$HOME/HyprArch/customs/grub/grub"
SDDM_FILE="$HOME/HyprArch/customs/SDDM/hyprarch-sddm/theme.conf"
HYPR_MON="$HOME/HyprArch/customs/hypr/confs/monitors.conf"

if ! command -v hyprland >/dev/null || ! command -v hyprctl >/dev/null; then
    err "This script must be run inside Hyprland.${E}"
    exit 1
fi

mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[] | "\(.name),\(.width)x\(.height)@\(.refreshRate|floor),\(.x)x\(.y)"')

info "Detected monitors:${E}"
for i in "${!MONITORS[@]}"; do
    echo "$((i+1))) ${MONITORS[$i]}"
done

read -p $'\e[34mSelect the main monitor number: \e[0m' SELECTED
if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || (( SELECTED < 1 || SELECTED > ${#MONITORS[@]} )); then
    err "Invalid choice.${E}"
    exit 1
fi

MAIN_MON="${MONITORS[$((SELECTED-1))]}"
MAIN_NAME=$(echo "$MAIN_MON" | cut -d',' -f1)
MAIN_RES=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f1)
MAIN_RATE=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f2)
WIDTH=$(echo "$MAIN_RES" | cut -d'x' -f1)
HEIGHT=$(echo "$MAIN_RES" | cut -d'x' -f2)

warn "Selected: $MAIN_NAME ($WIDTH x $HEIGHT @ $MAIN_RATE)${E}"

if [ -f "$GRUB_FILE" ]; then
    sed -i '/^GRUB_GFXMODE=/d' "$GRUB_FILE"
    echo "GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto" >> "$GRUB_FILE"
    echo "Updated GRUB: GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto"
else
    echo "GRUB configuration file not found: $GRUB_FILE"
fi

if [ -f "$SDDM_FILE" ]; then
    sed -i "s/^ScreenWidth=.*/ScreenWidth=\"$WIDTH\"/" "$SDDM_FILE"
    sed -i "s/^ScreenHeight=.*/ScreenHeight=\"$HEIGHT\"/" "$SDDM_FILE"
    warn "Updated SDDM: ${WIDTH} x ${HEIGHT}${E}"
else
    err "SDDM configuration file not found: $SDDM_FILE${E}"
fi

MON_LINE="monitor=${MAIN_NAME},${WIDTH}x${HEIGHT}@${MAIN_RATE},0x0,1"
mkdir -p "$(dirname "$HYPR_MON")"
echo "$MON_LINE" >> "$HYPR_MON"
warn "Added to monitors.conf: ${E}"
echo "$MON_LINE"

warn "Reloading Hyprland... ${E}"
if ! hyprctl reload && sleep 0.5; then
    err "Error reloading Hyprland. Please check logs.${E}"
    exit 1
fi
ok "Hyprland has been reloaded successfully.${E}"
exit 0
