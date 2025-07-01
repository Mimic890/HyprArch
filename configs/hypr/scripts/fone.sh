#!/bin/bash

# Папка с обоями
WALLPAPER_DIR="$HOME/.config/hypr/fone"
# Файл для хранения текущего индекса
INDEX_FILE="$HOME/.config/hypr/fone/.current_index"
# Получаем список файлов-обоев (отсортированный)
WALLPAPERS=("$WALLPAPER_DIR"/hyprfone*.jpg)
COUNT=${#WALLPAPERS[@]}

# Читаем текущий индекс
if [[ -f "$INDEX_FILE" ]]; then
    INDEX=$(cat "$INDEX_FILE")
else
    INDEX=0
fi

# Аргумент "next" - следующий обои
if [[ "$1" == "next" ]]; then
    INDEX=$(( (INDEX + 1) % COUNT ))
fi

# Устанавливаем обои через hyprctl (или hyprpaper через IPC)
hyprctl hyprpaper wallpaper "eDP-1,${WALLPAPERS[$INDEX]}"

# Сохраняем индекс
echo "$INDEX" > "$INDEX_FILE"
