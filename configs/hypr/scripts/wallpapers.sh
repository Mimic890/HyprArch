#!/bin/bash
INI="$HOME/.config/waypaper/config.ini"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
WALL=$(grep '^wallpaper *= *' "$INI" | cut -d '=' -f2- | xargs)
WALL="${WALL/#\~/$HOME}"
if [[ -f "$WALL" ]]; then
    sed -i "s|path = .*|path = $WALL|" "$HYPRLOCK_CONF"
    echo "Обои hyprlock обновлены на: $WALL"
else
    echo "Обои не найдены: $WALL"
fi
