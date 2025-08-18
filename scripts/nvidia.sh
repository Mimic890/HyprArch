#!/bin/bash
set -e

R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"
#
info(){ printf "${B}%s\n" "$*"; }
ok(){   printf "${G}%s\n" "$*"; }
warn(){ printf "${Y}%s\n" "$*"; }
err(){  printf "${R}%s\n" "$*" >&2; }

if ! lspci | grep -i nvidia &>/dev/null; then
    ok "No NVIDIA GPU detected. Skipping driver installation."
    exit 0
fi

info "NVIDIA GPU detected. Installing drivers and dependencies..."

PACKAGES=("nvidia" "nvidia-utils" "nvidia-settings" "opencl-nvidia" "egl-wayland")

for pkg in "${PACKAGES[@]}"; do
    info "Installing ${pkg}...${E} "
    if sudo pacman -S --needed --noconfirm "$pkg"; then
        ok "[SUCCESS]"
    else
        err "[FAILED]"
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
        ok "NVIDIA environment variables added to hyprland.conf"
    else
        warn "NVIDIA environment variables are already present in hyprland.conf"
    fi
else
    err "hyprland.conf not found. Please add the environment variables manually if needed."
fi

exit 0
