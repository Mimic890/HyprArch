#!/bin/bash
# Configuring SDDM
echo -e "\e[34m🖌️ Configuring SDDM...\e[0m"

# Copy SDDM theme
if [ -d "$HOME/HyprArch/customs/SDDM/hyprarch-sddm" ]; then
    sudo cp -r "$HOME/HyprArch/customs/SDDM/hyprarch-sddm" /usr/share/sddm/themes/
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✅ SDDM theme copied successfully\e[0m"
    else
        echo -e "\e[31m❌ Failed to copy SDDM theme\e[0m"
        echo -e "\e[31m❌ SDDM configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31m🚨 Folder SDDM/hyprarch-sddm not found\e[0m"
    echo -e "\e[31m❌ SDDM configuration failed. Aborting.\e[0m"
    exit 1
fi

# Copy SDDM configuration
if [ -f "$HOME/HyprArch/customs/SDDM/sddm.conf" ]; then
    sudo cp "$HOME/HyprArch/customs/SDDM/sddm.conf" /etc/sddm.conf
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✅ sddm.conf copied successfully\e[0m"
        echo -e "\e[32m✅ SDDM configured successfully.\e[0m"
        exit 0
    else
        echo -e "\e[31m❌ Failed to copy sddm.conf\e[0m"
        echo -e "\e[31m❌ SDDM configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31m🚨 File sddm.conf not found\e[0m"
    echo -e "\e[31m❌ SDDM configuration failed. Aborting.\e[0m"
    exit 1
fi

exit 0
