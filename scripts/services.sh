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


for dm in lightdm gdm; do
    if systemctl list-units --full | grep -q "$dm"; then
        sudo systemctl disable "$dm" || {
            err "Failed to disable $dm"
            exit 1
        }
        ok "Disabled $dm"
    fi
done
if systemctl list-units --full | grep -q "power-profiles-daemon"; then
    sudo systemctl enable power-profiles-daemon || {
        err "Failed to enable power-profiles-daemon"
        exit 1
    }
    ok "Enabled power-profiles-daemon"
else
    warn "power-profiles-daemon not found, skipping"
fi
sudo systemctl enable sddm || {
    err "Failed to enable sddm"
    exit 1
}
ok "Enabled sddm"
# Bluetooth setup
check_bluetooth() {
    local pkgs=("blueman" "bluez" "bluez-utils")
    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "All required Bluetooth packages are already installed."
        if ! systemctl is-enabled bluetooth &>/dev/null; then
            warn "Bluetooth service is not enabled."
            read -rp "Do you want to enable Bluetooth service now? [y/N]: " enable_bt
            if [[ "$enable_bt" =~ ^[Yy]$ ]]; then
                sudo systemctl enable --now bluetooth && ok "Bluetooth service enabled and started."
            else
                warn "Bluetooth service remains disabled."
            fi
        elif ! systemctl is-active bluetooth &>/dev/null; then
            warn "Bluetooth service is installed but not running."
            read -rp "Do you want to start Bluetooth service now? [y/N]: " start_bt
            if [[ "$start_bt" =~ ^[Yy]$ ]]; then
                sudo systemctl start bluetooth && ok "Bluetooth service started."
            else
                warn "Bluetooth service is not running."
            fi
        else
            ok "Bluetooth is already configured and running."
        fi

    else
        warn "Missing Bluetooth packages: ${missing[*]}"
        read -rp "Do you want to install and enable Bluetooth? [y/N]: " use_bt
        if [[ "$use_bt" =~ ^[Yy]$ ]]; then
            info "Installing Bluetooth packages: ${missing[*]}"
            sudo pacman -S --noconfirm "${missing[@]}" || {
                err "Failed to install Bluetooth packages"
                return 1
            }

            info "Enabling Bluetooth service..."
            sudo systemctl enable --now bluetooth || {
                err "Failed to enable Bluetooth service"
                return 1
            }

            if pacman -Q obexctl &>/dev/null || pacman -Si bluez &>/dev/null; then
                sudo systemctl enable --now obex.service &>/dev/null || true
            fi

            ok "Bluetooth installed and enabled."
        else
            warn "Bluetooth setup skipped."
        fi
    fi
}

check_bluetooth

exit 0