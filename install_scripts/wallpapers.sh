#!/bin/bash

# Цветной вывод
info()  { echo -e "\e[36m[🖼] $1\e[0m"; }
warn()  { echo -e "\e[33m⚠️  $1\e[0m"; }
error() { echo -e "\e[31m❌ $1\e[0m"; }
success() { echo -e "\e[32m✅ $1\e[0m"; }

# Пути
WALLPAPER_DIR="$HOME/.config/hyprarch/wallpapers"
LOG_FILE="$HOME/HyprArch/log.txt"

# Ссылки на папки
STATIC_URL="https://disk.yandex.ru/d/RnFqUzpMfx_EFQ"
LIVE_URL="https://disk.yandex.ru/d/N9qkFdXRHQQy0Q"

# Подготовка
mkdir -p "$WALLPAPER_DIR" "$HOME/HyprArch"
echo "[$(date)] Начата установка обоев" > "$LOG_FILE"

# Функция загрузки
download_folder() {
    local url="$1"
    local dest_dir="$2"

    API_URL="https://cloud-api.yandex.net/v1/disk/public/resources"
    FILES=$(curl -s "$API_URL?public_key=$url&limit=1000" | jq -r '.["_embedded"].items[] | @base64')

    for FILE in $FILES; do
        _jq() { echo "$FILE" | base64 --decode | jq -r "$1"; }
        NAME=$(_jq '.name')
        FILE_URL=$(_jq '.file')

        if [[ "$FILE_URL" == "null" ]]; then
            warn "Пропущен: $NAME (не файл)"
            continue
        fi

        DEST="$dest_dir/$NAME"
        info "📥 $NAME"

        wget --inet4-only --show-progress "$FILE_URL" -O "$DEST" >> "$LOG_FILE" 2>&1
    done
}

# Загрузка статичных
info "🔧 Загрузка статичных обоев..."
download_folder "$STATIC_URL" "$WALLPAPER_DIR"

# Спрашиваем про живые
read -p $'\e[36m[🖼] Установить живые обои? [y/N]: \e[0m' choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    info "🔧 Загрузка живых обоев..."
    download_folder "$LIVE_URL" "$WALLPAPER_DIR"
else
    warn "Пропущена установка живых обоев."
fi

success "✅ Установка завершена. Полный лог: $LOG_FILE"
