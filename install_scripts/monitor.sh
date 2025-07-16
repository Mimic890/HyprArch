#!/bin/bash

# === Пути к нужным файлам ===
GRUB_FILE="$HOME/HyprArch/customs/grub/grub"
SDDM_FILE="$HOME/HyprArch/customs/SDDM/hyprarch-sddm/theme.conf"

# === Проверка на Hyprland ===
if ! pgrep Hyprland >/dev/null || ! command -v hyprctl >/dev/null; then
    echo "❌ Этот скрипт работает только в Hyprland (через hyprctl)."
    exit 1
fi

# === Получаем список мониторов через hyprctl ===
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[] | "\(.name),\(.width)x\(.height)@\(.refreshRate|floor),\(.x)x\(.y)"')

# === Вывод мониторов ===
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

MAIN_MON="${MONITORS[$((SELECTED-1))]}"
MAIN_RES=$(echo "$MAIN_MON" | cut -d',' -f2 | cut -d'@' -f1)
WIDTH=$(echo "$MAIN_RES" | cut -d'x' -f1)
HEIGHT=$(echo "$MAIN_RES" | cut -d'x' -f2)

echo "✅ Выбран основной монитор: $MAIN_MON"
echo "📐 Разрешение: ${WIDTH}x${HEIGHT}"

# === Обновление GRUB ===
if [ -f "$GRUB_FILE" ]; then
    sed -i '/^GRUB_GFXMODE=/d' "$GRUB_FILE"
    echo "GRUB_GFXMODE=${WIDTH}x${HEIGHT},auto" >> "$GRUB_FILE"
    echo "✅ Обновлён: $GRUB_FILE"
else
    echo "⚠️ Не найден файл grub: $GRUB_FILE"
fi

# === Обновление SDDM ===
if [ -f "$SDDM_FILE" ]; then
    sed -i "s/^ScreenWidth=.*/ScreenWidth=\"$WIDTH\"/" "$SDDM_FILE"
    sed -i "s/^ScreenHeight=.*/ScreenHeight=\"$HEIGHT\"/" "$SDDM_FILE"
    echo "✅ Обновлён: $SDDM_FILE"
else
    echo "⚠️ Не найден файл sddm: $SDDM_FILE"
fi
