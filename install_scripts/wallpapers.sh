#!/bin/bash

# Color output
info()  { echo -e "\e[36m[🖼] $1\e[0m"; }
warn()  { echo -e "\e[33m⚠️  $1\e[0m"; }
error() { echo -e "\e[31m❌ $1\e[0m"; }
success() { echo -e "\e[32m✅ $1\e[0m"; }

# Paths
WALLPAPER_DIR="$HOME/.config/hyprarch/wallpapers"
LOG_FILE="$HOME/HyprArch/log.txt"

# Links to folders
STATIC_URL="https://disk.yandex.ru/d/RnFqUzpMfx_EFQ"
LIVE_URL="https://disk.yandex.ru/d/N9qkFdXRHQQy0Q"

# Preparation
mkdir -p "$WALLPAPER_DIR" "$HOME/HyprArch"
echo "[$(date)] Wallpaper installation has begun" > "$LOG_FILE"

# Download function
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
            warn "Missed: $NAME (not a file)"
            continue
        fi

        DEST="$dest_dir/$NAME"
        info "📥 $NAME"

        wget --inet4-only --show-progress "$FILE_URL" -O "$DEST" >> "$LOG_FILE" 2>&1
    done
}

# Asking a question about static wallpaper
read -p $'\e[36m[🖼] Set static wallpaper? [y/N]: \e[0m' static_choice
if [[ "$static_choice" =~ ^[Yy]$ ]]; then
    info "🔧 Loading static wallpapers..."
    download_folder "$STATIC_URL" "$WALLPAPER_DIR"
else
    warn "The static wallpaper setting has been omitted."
fi

# We ask about the living wallpapers
read -p $'\e[36m[🖼] Install live wallpaper? [y/N]: \e[0m' choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    info "🔧 Loading live wallpaper..."
    download_folder "$LIVE_URL" "$WALLPAPER_DIR"
else
    warn "Live wallpaper installation skipped."
fi

success "✅ Installation complete. Full log: $LOG_FILE"
