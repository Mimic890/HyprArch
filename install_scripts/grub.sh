#!/bin/bash

echo -e "\e[34m🔧 Configuring GRUB...\e[0m"

# Copying GRUB configuration
if [ -f "$HOME/HyprArch/customs/grub/grub" ]; then
    sudo cp "$HOME/HyprArch/customs/grub/grub" /etc/default/grub
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✅ grub config copied successfully\e[0m"
    else
        echo -e "\e[31m❌ Failed to copy grub config\e[0m"
        echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31m🚨 File grub not found\e[0m"
    echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
    exit 1
fi

# Copying GRUB theme
if [ -d "$HOME/HyprArch/customs/grub/hypr" ]; then
    sudo cp -r "$HOME/HyprArch/customs/grub/hypr" /usr/share/grub/themes/
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✅ GRUB theme copied successfully\e[0m"
    else
        echo -e "\e[31m❌ Failed to copy GRUB theme\e[0m"
        echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31m🚨 Folder grub/hypr not found\e[0m"
    echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
    exit 1
fi

# Updating GRUB configuration
if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
    echo -e "\e[32m✅ GRUB configuration generated successfully\e[0m"
else
    echo -e "\e[31m❌ Failed to generate GRUB config\e[0m"
    echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
    exit 1
fi
