#!/bin/bash

# Paths
GRUB_FILE="$HOME/HyprArch/customs/grub/grub"
SDDM_FILE="$HOME/HyprArch/customs/SDDM/hyprarch-sddm/theme.conf"
HYPR_MON="$HOME/HyprArch/configs/hypr/confs/monitors.conf"

# Environment check
if ! pgrep Hyprland >/dev/null || ! command -v hyprctl >/dev/null; then
    echo "❌ This script must be run in Hyprland."
    exit 1
fi

# We receive a list of monitors from Hyprland.
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[] | "\(.name),\(.width)x\(.height)@\(.refreshRate|floor),\(.x)x\(.y)"')

# Displaying the list
echo "📺 Monitors found:"
for i in "${!MONITORS[@]}"; do
    echo "$((i+1))) ${MONITORS[$i]}"
done

# Selecting the main
read -p "Select the main screen number:" SELECTED
if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || (( SELECTED < 1 || SELECTED > ${#MONITORS[@]} )); then
    echo "❌ Wrong choice."
    exit 1
fi

# Analyzing data
MAIN_MON="${MONITORS[$((SELECTED-1))]}"
MAIN_NAME=$(echo "$MAIN_MON" | cut -d',' -f1)
MAIN_RES=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f1)
MAIN_RATE=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f2)
WIDTH=$(echo "$MAIN_RES" | cut -d'x' -f1)
HEIGHT=$(echo "$MAIN_RES" | cut -d'x' -f2)

echo "✅ Выбран: $MAIN_NAME ($WIDTH x $HEIGHT @ $MAIN_RATE)"

# GRUB update
if [ -f "$GRUB_FILE" ]; then
    sed -i '/^GRUB_GFXMODE=/d' "$GRUB_FILE"
    echo "GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto" >> "$GRUB_FILE"
    echo "✅ GRUB updated: GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto"
else
    echo "⚠️ Grub file not found: $GRUB_FILE"
fi

# SDDM update
if [ -f "$SDDM_FILE" ]; then
    sed -i "s/^ScreenWidth=.*/ScreenWidth=\"$WIDTH\"/" "$SDDM_FILE"
    sed -i "s/^ScreenHeight=.*/ScreenHeight=\"$HEIGHT\"/" "$SDDM_FILE"
    echo "✅ SDDM updated: $WIDTH x $HEIGHT"
else
    echo "⚠️ SDDM file not found: $SDDM_FILE"
fi

# Adding monitor=... to monitors.conf
MON_LINE="monitor=${MAIN_NAME},${WIDTH}x${HEIGHT}@${MAIN_RATE},0x0,1"
mkdir -p "$(dirname "$HYPR_MON")"
echo "$MON_LINE" >> "$HYPR_MON"
echo "✅ Added a line to monitors.conf:"
echo "$MON_LINE"

echo "Reload Hyprland"
hyprctl reload
if [ $? -ne 0 ]; then
    echo "❌ Error when restarting Hyprland. Please check the logs."
    exit 1
fi
echo "✅ Hyprland has been rebooted."
exit 0
