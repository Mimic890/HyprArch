#!/bin/bash
# Installing yay
if command -v yay >/dev/null 2>&1; then
    echo -e "\e[32m✅ yay is already installed, skipping installation.\e[0m"
else
    echo -e "\e[34m🛠️ Cloning yay...\e[0m"
    cd "$HOME" >>"$HOME/HyprArch/log.txt" 2>&1 || {
        echo -e "\e[31m❌ Failed to change directory to $HOME\e[0m"
        exit 1
    }

    git clone https://aur.archlinux.org/yay.git "$HOME/yay" >>"$HOME/HyprArch/log.txt" 2>&1 || {
        echo -e "\e[31m❌ Failed to clone yay\e[0m"
        exit 1
    }

    cd "$HOME/yay" >>"$HOME/HyprArch/log.txt" 2>&1 || {
        echo -e "\e[31m❌ Failed to change directory to $HOME/yay\e[0m"
        exit 1
    }

    echo -e "\e[34m🔨 Building and installing yay...\e[0m"
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/99_yay_pacman > /dev/null
    sudo chmod 440 /etc/sudoers.d/99_yay_pacman >>"$HOME/HyprArch/log.txt" 2>&1

    makepkg -si --noconfirm >>"$HOME/HyprArch/log.txt" 2>&1 || {
        echo -e "\e[31m❌ Failed to install yay\e[0m"
        sudo rm -f /etc/sudoers.d/99_yay_pacman >>"$HOME/HyprArch/log.txt" 2>&1
        exit 1
    }

    sudo rm -f /etc/sudoers.d/99_yay_pacman >>"$HOME/HyprArch/log.txt" 2>&1
    rm -rf "$HOME/yay" >>"$HOME/HyprArch/log.txt" 2>&1
    echo -e "\e[32m✅ yay installed successfully.\e[0m"
    exit 0
fi
exit 0
    exit 0
fi
exit 0
