#!/bin/bash
# Installing yay
if command -v yay >/dev/null 2>&1; then
    echo -e "\e[32m✅ yay is already installed, skipping installation.\e[0m"
else
    echo -e "\e[34m🛠️ Cloning yay...\e[0m"
    cd "$HOME" || {
        echo -e "\e[31m❌ Failed to change directory to $HOME\e[0m"
        exit 1
    }

    git clone https://aur.archlinux.org/yay.git "$HOME/yay" || {
        echo -e "\e[31m❌ Failed to clone yay\e[0m"
        exit 1
    }

    cd "$HOME/yay" || {
        echo -e "\e[31m❌ Failed to change directory to $HOME/yay\e[0m"
        exit 1
    }

    echo -e "\e[34m🔨 Building and installing yay...\e[0m"
    # Allow pacman without password for this user temporarily
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/99_yay_pacman > /dev/null
    sudo chmod 440 /etc/sudoers.d/99_yay_pacman

    makepkg -si --noconfirm || {
        echo -e "\e[31m❌ Failed to install yay\e[0m"
        # Remove sudoers rule on failure
        sudo rm -f /etc/sudoers.d/99_yay_pacman
        exit 1
    }

    # Remove the temporary sudoers rule
    sudo rm -f /etc/sudoers.d/99_yay_pacman
    rm -rf "$HOME/yay"
    echo -e "\e[32m✅ yay installed successfully.\e[0m"
    exit 0
fi
exit 0
