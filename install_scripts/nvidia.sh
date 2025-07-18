#!/bin/bash
# Checking for an NVIDIA graphics card
if ! lspci | grep -i nvidia &>/dev/null; then
    echo -e "\e[32mNVIDIA GPU не обнаружена. Пропускаем установку драйверов.\e[0m"
    exit 0
fi

echo -e "\e[34mNVIDIA GPU detected. Installing drivers and dependencies...\e[0m"

# Installing each package separately with status output
PACKAGES=("nvidia" "nvidia-utils" "nvidia-settings" "egl-wayland")
for pkg in "${PACKAGES[@]}"; do
    echo -ne "\e[36m⏳ Installing $pkg...\e[0m "
    if sudo pacman -S --needed "$pkg"; then
        echo -e "\e[32m[SUCCESS]\e[0m"
    else
        echo -e "\e[31m[FAILED]\e[0m"
    fi
done

# Adding environment variables to the Hyprland config
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Check if variables have already been added
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
        echo -e "\e[32mNVIDIA environment variables added to hyprland.conf\e[0m"
    else
        echo -e "\e[33mNVIDIA environment variables already present in hyprland.conf\e[0m"
    fi
else
    echo -e "\e[31mhyprland.conf not found. Add variables manually if needed.\e[0m"
fi

exit 0
