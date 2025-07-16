#!/bin/bash
#/////////////////////////////////////
#// HyprArch Base Installation Script //
#/////////////////////////////////////
clear

# Exit on error
set -e

# Update system and install base packages
echo -e "\e[34m🔧 Updating system...\e[0m"
sudo pacman -Syu --needed base-devel hyprland sddm grub --noconfirm --quiet >>log.txt 2>&1 || {
    echo -e "\e[31m❌ System update or base package installation error\e[0m"
    exit 1
}

# Install video drivers
echo -e "\e[34m🔧 Installing video drivers...\e[0m"
bash "$HOME/HyprArch/install_scripts/nvidia.sh" || {
    echo -e "\e[31m❌ Video driver installation failed\e[0m"
    exit 1
}

# Configure monitor
MONITOR_SCRIPT="$HOME/HyprArch/install_scripts/monitor.sh"
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo -e "\e[31m❌ Скрипт монитора не найден: $MONITOR_SCRIPT\e[0m"
    exit 1
fi
chmod +x "$MONITOR_SCRIPT"
echo -e "\e[34m📡 Запуск настройки монитора...\e[0m"
if ! "$MONITOR_SCRIPT"; then
    echo -e "\e[31m❌ Ошибка при выполнении $MONITOR_SCRIPT\e[0m"
    exit 1
fi
echo -e "\e[32m✅ Настройка монитора завершена успешно.\e[0m"

# Configure SDDM
echo -e "\e[34m🔧 Configuring SDDM...\e[0m"
bash "$HOME/HyprArch/install_scripts/sddm.sh" || {
    echo -e "\e[31m❌ SDDM configuration failed\e[0m"
    exit 1
}

# Configure GRUB
echo -e "\e[34m🔧 Configuring GRUB...\e[0m"
bash "$HOME/HyprArch/install_scripts/grub.sh" || {
    echo -e "\e[31m❌ GRUB configuration failed\e[0m"
    exit 1
}

echo -e "\e[32m✅ Base system installed successfully.\e[0m"
exit 0
