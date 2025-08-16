#!/bin/bash
set -e
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
E="\e[0m"

if ! lspci | grep -i nvidia &>/dev/null; then
    echo -e "${G}No NVIDIA GPU detected. Skipping driver installation.${E}"
    exit 0
fi

echo -e "${B}NVIDIA GPU detected. Installing drivers and dependencies...${E}"

PACKAGES=("nvidia" "nvidia-utils" "nvidia-settings" "opencl-nvidia" "egl-wayland")

for pkg in "${PACKAGES[@]}"; do
    echo -ne "${B}Installing ${pkg}...${E} "
    if sudo pacman -S --needed --noconfirm "$pkg"; then
        echo -e "${G}[SUCCESS]${E}"
    else
        echo -e "${R}[FAILED]${E}"
    fi
done

HYPR_CONF="$HOME/.config/hypr/confs/nvidia.conf"
if [ -f "$HYPR_CONF" ]; then
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
        echo -e "${G}NVIDIA environment variables added to hyprland.conf${E}"
    else
        echo -e "${Y}NVIDIA environment variables are already present in hyprland.conf${E}"
    fi
else
    echo -e "${R}hyprland.conf not found. Please add the environment variables manually if needed.${E}"
fi

exit 0
