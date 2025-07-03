#!/bin/bash
#  //////////////////////////////////
# // HyprArch installation script //
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

#-------------------------------------------#
#   Updating system and installing packages #
#-------------------------------------------#
if [ ! -f ~/HyprArch/pkg/pkglist.txt ]; then
    echo -e "\e[31m🚨 File pkglist.txt not found\e[0m"
    exit 1
fi

echo -e "\e[34m🔄 Updating system...\e[0m"
sudo pacman -Syu --needed base-devel --noconfirm --quiet >>log.txt 2>&1 || {
    echo -e "\e[31m❌ System update error\e[0m"
    exit 1
}

# --- Новый блок: Проверка и установка пакетов из pkglist.txt ---
echo -e "\e[34m📦 Проверка установленных пакетов...\e[0m"
pkglist=($(cat ~/HyprArch/pkg/pkglist.txt))
installed_pkgs=()
missing_pkgs=()
for pkg in "${pkglist[@]}"; do
    if pacman -Qq "$pkg" &>>log.txt; then
        installed_pkgs+=("$pkg")
    else
        missing_pkgs+=("$pkg")
    fi
done

if [ ${#installed_pkgs[@]} -gt 0 ]; then
    echo -e "\e[32m✅ Уже установлены: ${installed_pkgs[*]}\e[0m"
fi

if [ ${#missing_pkgs[@]} -eq 0 ]; then
    echo -e "\e[32mВсе необходимые пакеты уже установлены.\e[0m"
else
    echo -e "\e[34m📦 Установка недостающих пакетов...\e[0m"
    for pkg in "${missing_pkgs[@]}"; do
        echo -e "\e[36m→ Устанавливается: $pkg\e[0m"
        if sudo pacman -S --noconfirm --quiet "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m   $pkg установлен успешно.\e[0m"
        else
            echo -e "\e[31m   Ошибка установки $pkg\e[0m"
            exit 1
        fi
    done
fi

#------------------#
#  installing yay  #
#------------------#
echo -e "\e[34m🔨 Installing yay (AUR)...\e[0m"
bash "$HOME/HyprArch/install_scripts/yay.sh" >>log.txt 2>&1
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

echo -e "\e[35m📥 Проверка установленных AUR пакетов...\e[0m"
aurlist=($(cat ~/HyprArch/pkg/aur.txt))
installed_aur=()
missing_aur=()
for pkg in "${aurlist[@]}"; do
    if pacman -Qq "$pkg" &>>log.txt; then
        installed_aur+=("$pkg")
    else
        missing_aur+=("$pkg")
    fi
done

if [ ${#installed_aur[@]} -gt 0 ]; then
    echo -e "\e[32m✅ Уже установлены (AUR): ${installed_aur[*]}\e[0m"
fi

if [ ${#missing_aur[@]} -eq 0 ]; then
    echo -e "\e[32mВсе необходимые AUR пакеты уже установлены.\e[0m"
else
    echo -e "\e[35m📥 Установка недостающих AUR пакетов...\e[0m"
    for pkg in "${missing_aur[@]}"; do
        echo -e "\e[36m→ Устанавливается (AUR): $pkg\e[0m"
        if yay -S --noconfirm --quiet "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m   $pkg (AUR) установлен успешно.\e[0m"
        else
            echo -e "\e[31m   Ошибка установки $pkg (AUR)\e[0m"
            exit 1
        fi
    done
fi

#----------------------#
# Configuring services #
#----------------------#
echo -e "\e[34m🔧 Configuring services...\e[0m"
if systemctl list-units --full | grep -q lightdm; then
    sudo systemctl disable lightdm >>log.txt 2>&1 || {
        echo -e "\e[31m❌ Failed to disable lightdm\e[0m"
        exit 1
    }
fi

for service in bluetooth power-profiles-daemon; do
    if systemctl list-units --full | grep -q "$service"; then
        sudo systemctl enable "$service" >>log.txt 2>&1 || {
            echo -e "\e[31m❌ Failed to configure $service\e[0m"
            exit 1
        }
    else
        echo -e "\e[33m⚠️  Service $service not found, skipping.\e[0m"
    fi
done

sudo systemctl enable sddm >>log.txt 2>&1 || {
    echo -e "\e[31m❌ Failed to configure sddm\e[0m"
    exit 1
}

#---------------------------#
#  Create base directories  #
#---------------------------#
LANG=en_US.UTF-8 xdg-user-dirs-update --force

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
        bash "$HOME/HyprArch/install_scripts/fish.sh" >>log.txt 2>&1
        if [ $? -ne 0 ]; then
            echo -e "\e[31m❌ Fish shell installation failed. Aborting installation.\e[0m"
            exit 1
        fi
        ;;
    3)
        echo -e "\e[34m Installing zsh shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/zsh.sh" >>log.txt 2>&1
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
    bash "$HOME/HyprArch/install_scripts/gtk.sh" >>log.txt 2>&1
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
    cp -r "$HOME/HyprArch/configs/"* "$HOME/.config/" >>log.txt 2>&1
else
    echo -e "\e[31m🚨 configs folder not found\e[0m"
fi

#---------------------------#
#   Wallpapers installation #
#---------------------------#
echo -e "\e[34m🖼  Installing wallpapers...\e[0m"
if bash "$HOME/HyprArch/install_scripts/wallpapers.sh"; then
    echo -e "\e[32m✅ Wallpapers installed successfully.\e[0m"
else
    echo -e "\e[31m❌ Wallpapers installation failed. Check log.txt for details.\e[0m"
fi

#---------------------------#
#  Update waybar interface  #
#---------------------------#
# Определяем активный сетевой интерфейс (без loopback)
WAYBAR_IFACE=$(ip route | awk '/default/ {print $5; exit}')

if [ -n "$WAYBAR_IFACE" ]; then
    for cfg in "$HOME/.config/waybar"/config*; do
        [ -f "$cfg" ] || continue
        if grep -q '"interface":' "$cfg"; then
            cp "$cfg" "$cfg.bak"
            sed -i "s/\"interface\": \".*\"/\"interface\": \"$WAYBAR_IFACE\"/" "$cfg"
            echo -e "\e[34m🔄 Обновлён интерфейс в $cfg\e[0m"
        fi
    done
    echo -e "\e[32m✅ Waybar config updated: wpl3s0 → $WAYBAR_IFACE\e[0m"
else
    echo -e "\e[33m⚠️  Не удалось определить сетевой интерфейс для Waybar. Проверьте вручную.\e[0m"
fi


#---------------------------#
#   NVIDIA driver setup     #
#---------------------------#
bash "$HOME/HyprArch/install_scripts/nvidia.sh" >>log.txt 2>&1

#-------------------------------#
#   AstroNvim & HyprArch neovim #
#-------------------------------#
read -p $'\e[36m Install AstroNvim? (y/n): \e[0m' install_astronvim
if [[ "$install_astronvim" =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim >>log.txt 2>&1
    rm -rf ~/.config/nvim/.git
fi

#----------------------#
#  Install music utils #
#----------------------#
read -p $'\e[36m Install music utils? (y/n): \e[0m' install_utils
if [[ "$install_utils" =~ ^[Yy]$ ]]; then
    sudo pacman -S lsp-plugins easyeffects >>log.txt 2>&1
fi

#-------------#
#    sddm     #
#-------------#
echo -e "\e[34m Configuring SDDM...\e[0m"
bash "$HOME/HyprArch/install_scripts/sddm.sh" >>log.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\e[31m❌ SDDM configuration failed. Aborting installation.\e[0m"
    exit 1
fi

#--------------#
#     grub     #
#--------------#
echo -e "\e[34m Configuring GRUB...\e[0m"
bash "$HOME/HyprArch/install_scripts/grub.sh" >>log.txt 2>&1
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
exit 0
