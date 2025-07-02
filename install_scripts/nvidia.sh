#!/bin/bash
# Проверка наличия видеокарты NVIDIA
if ! lspci | grep -i nvidia &>/dev/null; then
    echo -e "\e[33mNVIDIA GPU не обнаружена. Пропускаем установку драйверов.\e[0m"
    exit 0
fi

echo -e "\e[34mОбнаружена NVIDIA GPU. Устанавливаем драйверы и зависимости...\e[0m"

# Установка проприетарного драйвера и зависимостей
sudo pacman -S --needed nvidia nvidia-utils nvidia-settings lib32-nvidia-utils egl-wayland

# Добавление переменных окружения в конфиг Hyprland
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Проверяем, были ли уже добавлены переменные
    if ! grep -q "NVIDIA ENV BEGIN" "$HYPR_CONF"; then
        cat <<EOF >> "$HYPR_CONF"

# NVIDIA ENV BEGIN
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_EGL_NO_MODIFIERS,1
# NVIDIA ENV END
EOF
        echo -e "\e[32m✅ Переменные окружения для NVIDIA добавлены в hyprland.conf\e[0m"
    else
        echo -e "\e[33mПеременные окружения для NVIDIA уже присутствуют в hyprland.conf\e[0m"
    fi
else
    echo -e "\e[31mФайл hyprland.conf не найден. Добавьте переменные вручную при необходимости.\e[0m"
fi

exit 0
