#!/bin/bash

# === Пути ===
GRUB_FILE="$HOME/HyprArch/customs/grub/grub"
SDDM_FILE="$HOME/HyprArch/customs/SDDM/hyprarch-sddm/theme.conf"
HYPR_MON="$HOME/HyprArch/configs/hypr/confs/monitors.conf"

# === Проверка среды ===
if ! pgrep Hyprland >/dev/null || ! command -v hyprctl >/dev/null; then
    echo "❌ Этот скрипт должен быть запущен в Hyprland."
    exit 1
fi

# === Получаем список мониторов из Hyprland ===
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[] | "\(.name),\(.width)x\(.height)@\(.refreshRate|floor),\(.x)x\(.y)"')

# === Выводим список ===
echo "📺 Найдены мониторы:"
for i in "${!MONITORS[@]}"; do
    echo "$((i+1))) ${MONITORS[$i]}"
done

# === Выбор основного ===
read -p "Выберите номер основного экрана: " SELECTED
if ! [[ "$SELECTED" =~ ^[0-9]+$ ]] || (( SELECTED < 1 || SELECTED > ${#MONITORS[@]} )); then
    echo "❌ Неверный выбор."
    exit 1
fi

# === Разбираем данные ===
MAIN_MON="${MONITORS[$((SELECTED-1))]}"
MAIN_NAME=$(echo "$MAIN_MON" | cut -d',' -f1)
MAIN_RES=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f1)
MAIN_RATE=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f2)
WIDTH=$(echo "$MAIN_RES" | cut -d'x' -f1)
HEIGHT=$(echo "$MAIN_RES" | cut -d'x' -f2)

echo "✅ Выбран: $MAIN_NAME ($WIDTH x $HEIGHT @ $MAIN_RATE)"

# === Обновление GRUB ===
if [ -f "$GRUB_FILE" ]; then
    sed -i '/^GRUB_GFXMODE=/d' "$GRUB_FILE"
    echo "GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto" >> "$GRUB_FILE"
    echo "✅ GRUB обновлён: GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto"
else
    echo "⚠️ Файл grub не найден: $GRUB_FILE"
fi

# === Обновление SDDM ===
if [ -f "$SDDM_FILE" ]; then
    sed -i "s/^ScreenWidth=.*/ScreenWidth=\"$WIDTH\"/" "$SDDM_FILE"
    sed -i "s/^ScreenHeight=.*/ScreenHeight=\"$HEIGHT\"/" "$SDDM_FILE"
    echo "✅ SDDM обновлён: $WIDTH x $HEIGHT"
else
    echo "⚠️ Файл SDDM не найден: $SDDM_FILE"
fi

# === Добавление monitor=... в monitors.conf ===
MON_LINE="monitor=${MAIN_NAME},${WIDTH}x${HEIGHT}@${MAIN_RATE},0x0,1"
mkdir -p "$(dirname "$HYPR_MON")"
echo "$MON_LINE" >> "$HYPR_MON"
echo "✅ Добавлена строка в monitors.conf:"
echo "$MON_LINE"
