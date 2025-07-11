#!/bin/bash
# Install zsh
echo -e "\e[34m🔧 Installing zsh shell...\e[0m"
sudo pacman -S --noconfirm zsh >>"$HOME/HyprArch/log.txt" 2>&1 || {
    echo -e "\e[31m❌ Failed to install zsh shell.\e[0m"
    exit 1
}

# Set zsh as the default shell for the current user
if ! grep -q "/usr/bin/zsh" /etc/shells; then
    echo "/usr/bin/zsh" | sudo tee -a /etc/shells >>"$HOME/HyprArch/log.txt" 2>&1
fi
chsh -s /usr/bin/zsh || {
    echo -e "\e[31m❌ Failed to set zsh as the default shell.\e[0m"
    exit 1
}

# Install zinit
echo -e "\e[34m🔧 Installing zinit...\e[0m"
mkdir -p "$HOME/.local/share/zinit"
if [ -d "$HOME/.local/share/zinit/zinit.git" ]; then
    rm -rf "$HOME/.local/share/zinit/zinit.git" >>"$HOME/HyprArch/log.txt" 2>&1
fi
git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" >>"$HOME/HyprArch/log.txt" 2>&1 || {
    echo -e "\e[31m❌ Failed to install zinit.\e[0m"
    exit 1
}

# Install starship
echo -e "\e[34m🔧 Installing starship...\e[0m"
curl -sS https://starship.rs/install.sh | sh >>"$HOME/HyprArch/log.txt" 2>&1 || {
    echo -e "\e[31m❌ Failed to install starship.\e[0m"
    exit 1
}

# Copy starship.toml config
echo -e "\e[34m📋 Copying starship.toml config...\e[0m"
mkdir -p "$HOME/.config"
if [ -f "$HOME/HyprArch/customs/zsh/starship.toml" ]; then
    cp "$HOME/HyprArch/customs/zsh/starship.toml" "$HOME/.config/" >>"$HOME/HyprArch/log.txt" 2>&1
else
    echo -e "\e[31m❌ starship.toml not found.\e[0m"
    exit 1
fi

# Copy .zshrc config
echo -e "\e[34m📋 Copying .zshrc config...\e[0m"
if [ -f "$HOME/.zshrc" ]; then
    rm -f "$HOME/.zshrc" >>"$HOME/HyprArch/log.txt" 2>&1
fi
if [ -f "$HOME/HyprArch/customs/zsh/.zshrc" ]; then
    mv "$HOME/HyprArch/customs/zsh/.zshrc" "$HOME/" >>"$HOME/HyprArch/log.txt" 2>&1
else
    echo -e "\e[31m❌ .zshrc not found in customs.\e[0m"
    exit 1
fi

echo -e "\e[32m✅ Zsh shell installed and configured successfully.\e[0m"
exit 0
