#!/bin/bash
# Configuring SDDM
# Copy SDDM theme
if [ -d "$HOME/HyprArch/customs/SDDM/hyprarch-sddm" ]; then
    sudo cp -r "$HOME/HyprArch/customs/SDDM/hyprarch-sddm" /usr/share/sddm/themes/ >>"$HOME/HyprArch/log.txt" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "\e[32mSDDM theme copied successfully\e[0m"
    else
        echo -e "\e[31mFailed to copy SDDM theme\e[0m"
        echo -e "\e[31mSDDM configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31mFolder SDDM/hyprarch-sddm not found\e[0m"
    echo -e "\e[31mSDDM configuration failed. Aborting.\e[0m"
    exit 1
fi

# Copy SDDM configuration
if [ -f "$HOME/HyprArch/customs/SDDM/sddm.conf" ]; then
    sudo cp "$HOME/HyprArch/customs/SDDM/sddm.conf" /etc/sddm.conf >>"$HOME/HyprArch/log.txt" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "\e[32msddm.conf copied successfully\e[0m"
        echo -e "\e[32mSDDM configured successfully.\e[0m"
        exit 0
    else
        echo -e "\e[31mFailed to copy sddm.conf\e[0m"
        echo -e "\e[31mSDDM configuration failed. Aborting.\e[0m"
        exit 1
    fi
else
    echo -e "\e[31mFile sddm.conf not found\e[0m"
    echo -e "\e[31mSDDM configuration failed. Aborting.\e[0m"
    exit 1
fi

exit 0
