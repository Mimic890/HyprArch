#!/bin/bash
#//////////////////////////////////
#// HyprArch Main Control Script //
#//////////////////////////////////
clear

# Make all install scripts executable
chmod +x "$HOME/HyprArch/install_scripts/"*

# Exit on error
set -e

# Ask for sudo password once and keep it alive
echo -e "\e[34m🔑 Administrator password required for installation. Please enter your password:\e[0m"
sudo -v
# Refresh sudo timestamp until script ends
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_REFRESH_PID=$!
trap 'kill $SUDO_REFRESH_PID 2>/dev/null' EXIT

# Check if user is in Hyprland
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || command -v hyprctl &>/dev/null; then
    echo -e "\e[32m✅ Detected Hyprland environment. Starting full installation...\e[0m"
    bash "$HOME/HyprArch/install_scripts/install_full.sh"
else
    echo -e "\e[33m⚠️  Hyprland not detected. Starting base system installation...\e[0m"
    bash "$HOME/HyprArch/install_scripts/install_base.sh"

    # After base installation, check if Hyprland is now available
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || command -v hyprctl &>/dev/null; then
        echo -e "\e[32m✅ Hyprland detected after base installation. Starting full installation...\e[0m"
        bash "$HOME/HyprArch/install_scripts/install_full.sh"
    else
        echo -e "\e[33m⚠️  Hyprland still not detected. Full installation skipped.\e[0m"
        echo -e "\e[32m🎉 Base system installation completed successfully! 🚀\e[0m"
        echo -e "\e[36mWould you like to reboot now? (y/n): \e[0m"
        read -r reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo -e "\e[34m🔄 Rebooting...\e[0m"
            sudo reboot
        fi
    fi
fi

echo -e "\e[32m🎉 Installation completed successfully! 🚀\e[0m"
exit 0
