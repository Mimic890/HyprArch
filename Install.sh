#!/bin/bash
#  //////////////////////////////////
# // HyprArch installation script //
#//////////////////////////////////
clear
# Make all install scripts executable
chmod +x "$HOME/HyprArch/install_scripts/"*
# Logging to file and terminal simultaneously
exec > >(tee -a log.txt) 2>&1
# Exit on error
set -e

# Ask for sudo password once and keep it alive
echo -e "\e[34m🔑 Administrator password required for installation. Please enter your password:\e[0m"
sudo -v
# Refresh sudo timestamp until script ends
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_REFRESH_PID=$!
trap 'kill $SUDO_REFRESH_PID 2>/dev/null' EXIT

#-------------------------------------------#
#   Updating system and installing packages #
#-------------------------------------------#
if [ ! -f ~/HyprArch/pkg/pkglist.txt ]; then
    echo -e "\e[31m🚨 File pkglist.txt not found\e[0m"
    exit 1
fi

echo -e "\e[34m🔄 Updating system...\e[0m"
sudo pacman -Syu --needed base-devel || {
    echo -e "\e[31m❌ System update error\e[0m"
    exit 1
}

echo -e "\e[34m📦 Installing packages from pkglist.txt...\e[0m"
sudo pacman -S --needed $(cat ~/HyprArch/pkg/pkglist.txt) || {
    echo -e "\e[31m❌ Package installation error\e[0m"
    exit 1
}

#------------------#
#  installing yay  #
#------------------#
echo -e "\e[34m🔨 Installing yay (AUR)...\e[0m"
bash "$HOME/HyprArch/install_scripts/yay.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31m❌ yay installation failed. Aborting installation.\e[0m"
    exit 1
fi

#-------------------------#
# Installing AUR packages #
#-------------------------#
if [ ! -f ~/HyprArch/pkg/aur.txt ]; then
    echo -e "\e[31m🚨 File aur.txt not found\e[0m"
    exit 1
fi

echo -e "\e[35m📥 Installing AUR packages...\e[0m"
yay -S --needed $(cat ~/HyprArch/pkg/aur.txt) || {
    echo -e "\e[31m❌ Failed to install AUR packages\e[0m"
    exit 1
}

#----------------------#
# Configuring services #
#----------------------#
echo -e "\e[34m🔧 Configuring services...\e[0m"
if systemctl list-units --full | grep -q lightdm; then
    sudo systemctl disable lightdm || {
        echo -e "\e[31m❌ Failed to disable lightdm\e[0m"
        exit 1
    }
fi

for service in bluetooth power-profiles-daemon; do
    if systemctl list-units --full | grep -q "$service"; then
        sudo systemctl enable "$service" || {
            echo -e "\e[31m❌ Failed to configure $service\e[0m"
            exit 1
        }
    else
        echo -e "\e[33m⚠️  Service $service not found, skipping.\e[0m"
    fi
done

sudo systemctl enable sddm || {
    echo -e "\e[31m❌ Failed to configure sddm\e[0m"
    exit 1
}

#---------------------------#
#  Create base directories  #
#---------------------------#
mkdir -p ~/Pictures
mkdir -p ~/Videos
mkdir -p ~/Documents
mkdir -p ~/Downloads

#---------------------------#
#   SHELL SELECTION         #
#---------------------------#
echo -e "\e[36m Which shell do you want to install?\e[0m"
echo -e "\e[36m 1) Keep current shell (default)\e[0m"
echo -e "\e[36m 2) Install fish shell\e[0m"
echo -e "\e[36m 3) Install zsh shell\e[0m"
read -p $'\e[36m Enter your choice [1/2/3]: \e[0m' shell_choice

case "$shell_choice" in
    2)
        echo -e "\e[34m Installing fish shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/fish.sh"
        if [ $? -ne 0 ]; then
            echo -e "\e[31m❌ Fish shell installation failed. Aborting installation.\e[0m"
            exit 1
        fi
        ;;
    3)
        echo -e "\e[34m Installing zsh shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/zsh.sh"
        if [ $? -ne 0 ]; then
            echo -e "\e[31m❌ Zsh shell installation failed. Aborting installation.\e[0m"
            exit 1
        fi
        ;;
    *)
        echo -e "\e[34m Keeping current shell. No changes will be made.\e[0m"
        ;;
esac

#---------------------------#
#   GTK Theme Installation  #
#---------------------------#
read -p $'\e[36m Install GTK theme? (y/n): \e[0m' install_gtk
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/install_scripts/gtk.sh"
    if [ $? -ne 0 ]; then
        echo -e "\e[31m❌ GTK theme installation failed. Aborting installation.\e[0m"
        exit 1
    fi
fi

#---------------------------#
#   Copying configurations  #
#---------------------------#
echo -e "\e[34m📋 Copying configurations...\e[0m"
if [ -d "$HOME/HyprArch/configs" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$HOME/HyprArch/configs/"* "$HOME/.config/"
else
    echo -e "\e[31m🚨 configs folder not found\e[0m"
fi

#---------------------------#
#  Update waybar interface  #
#---------------------------#
# Определяем активный сетевой интерфейс (без loopback)
WAYBAR_IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -n "$WAYBAR_IFACE" ]; then
    for cfg in "$HOME/.config/waybar"/config*; do
        [ -f "$cfg" ] && sed -i "s/wpl3s0/$WAYBAR_IFACE/g" "$cfg"
    done
    echo -e "\e[32m✅ Waybar config updated: wpl3s0 → $WAYBAR_IFACE\e[0m"
else
    echo -e "\e[33m⚠️  Не удалось определить сетевой интерфейс для waybar. Проверьте вручную.\e[0m"
fi

#---------------------------#
#   NVIDIA driver setup     #
#---------------------------#
bash "$HOME/HyprArch/install_scripts/nvidia.sh"

#-------------------------------#
#   AstroNvim & HyprArch neovim #
#-------------------------------#
read -p $'\e[36m Install AstroNvim? (y/n): \e[0m' install_astronvim
if [[ "$install_astronvim" =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
fi

#----------------------#
#  Install music utils #
#----------------------#
read -p $'\e[36m Install music utils? (y/n): \e[0m' install_utils
if [[ "$install_utils" =~ ^[Yy]$ ]]; then
    sudo pacman -S lsp-plugins easyeffects
fi

#-------------#
#    sddm     #
#-------------#
echo -e "\e[34m Configuring SDDM...\e[0m"
bash "$HOME/HyprArch/install_scripts/sddm.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31m❌ SDDM configuration failed. Aborting installation.\e[0m"
    exit 1
fi

#--------------#
#     grub     #
#--------------#
echo -e "\e[34m Configuring GRUB...\e[0m"
bash "$HOME/HyprArch/install_scripts/grub.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31m❌ GRUB configuration failed. Aborting installation.\e[0m"
    exit 1
fi

echo -e "\e[34m Install more programms...\e[0m"
bash "$HOME/HyprArch/install_scripts/programms.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31m❌ Install more programms failed. Aborting installation.\e[0m"
    exit 1
fi

if pacman -Q visual-studio-code-bin &>/dev/null; then
	if bash "$HOME/HyprArch/install_scripts/vs-code.sh"; then
		echo -e "\e[32m✅ Кастом HyprVSCode установлен успешно!\e[0m"
	else
		echo -e "\e[31m❌ Ошибка при установке кастома HyprVSCode!\e[0m"
	fi
else
	echo "VS-Code is not installing, skipping install custom"
fi

# Going to HyprArch directory
if cd "$HOME/HyprArch"; then
    echo -e "\e[32m📂 Changed directory to HyprArch\e[0m"
    echo -e "\e[32m✅ GRUB configured successfully.\e[0m"
    exit 0
else
    echo -e "\e[31m❌ Failed to change directory to $HOME/HyprArch\e[0m"
    echo -e "\e[31m❌ GRUB configuration failed. Aborting.\e[0m"
    exit 1
fi

echo -e "\e[32m🎉 Installation completed successfully! 🚀\e[0m"
exit 0
