#!/bin/bash

set -e

# Цветной вывод
info() { echo -e "\e[1;36m[*]\e[0m $1"; }
ok()   { echo -e "\e[1;32m[✓]\e[0m $1"; }
warn() { echo -e "\e[1;33m[!]\e[0m $1"; }

# Проверка зависимостей
if ! command -v jq &>/dev/null || ! command -v wget &>/dev/null; then
    warn "Устанавливаются необходимые пакеты (jq, wget)..."
    sudo pacman -S jq wget --noconfirm
fi

# Пути и ссылки
BASE_DIR="$HOME/.config/hyprarch/wallpapers"
STATIC_DIR="$BASE_DIR/Static"
LIVE_DIR="$BASE_DIR/Live"

STATIC_URL="https://disk.yandex.ru/d/RnFqUzpMfx_EFQ"
LIVE_URL="https://disk.yandex.ru/d/N9qkFdXRHQQy0Q"

mkdir -p "$STATIC_DIR" "$LIVE_DIR"

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
        info "Загрузка $NAME → $DEST"

        wget --progress=bar:force:noscroll --show-progress "$FILE_URL" -O "$DEST" 2>&1 | \
            grep --line-buffered -E "(\%)|([KMG]?B)" || true
    done
}

# Загрузка статичных обоев
info "Загрузка статичных обоев..."
download_folder "$STATIC_URL" "$STATIC_DIR"
ok "Статичные обои загружены в $STATIC_DIR"

# Живые обои — опционально
read -p $'\e[1;34mХотите установить живые обои? (y/N): \e[0m' choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    info "Загрузка живых обоев..."
    download_folder "$LIVE_URL" "$LIVE_DIR"
    ok "Живые обои загружены в $LIVE_DIR"
else
    warn "Живые обои не загружены."
fi

ok "Установка завершена."
