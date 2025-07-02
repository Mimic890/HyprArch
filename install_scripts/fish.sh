#!/bin/bash
# Install fish shell
echo -e "\e[34mInstalling fish shell...\e[0m"
sudo pacman -S --noconfirm fish >>"$HOME/HyprArch/log.txt" 2>&1 || {
    echo -e "\e[31m❌ Failed to install fish shell.\e[0m"
    exit 1
}

# Set fish as the default shell for the current user
if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "/usr/bin/fish" | sudo tee -a /etc/shells >>"$HOME/HyprArch/log.txt" 2>&1
fi
chsh -s /usr/bin/fish >>"$HOME/HyprArch/log.txt" 2>&1 || {
    echo -e "\e[31m❌ Failed to set fish as the default shell.\e[0m"
    exit 1
}

# Copy fish configuration
echo -e "\e[34mCopying fish configuration...\e[0m"
mkdir -p "$HOME/.config"
if [ -d "$HOME/HyprArch/customs/fish" ]; then
    cp -r "$HOME/HyprArch/customs/fish" "$HOME/.config/" >>"$HOME/HyprArch/log.txt" 2>&1
else
    echo -e "\e[31m❌ Fish config directory not found.\e[0m"
    exit 1
fi

echo -e "\e[32mFish shell installed and configured successfully.\e[0m"
exit 0
