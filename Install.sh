#!/bin/bash
clear
echo "  //////////////////////////////////
 // HyprArch installation script //
//////////////////////////////////"
# Make all install scripts executable
chmod +x "$HOME/HyprArch/install_scripts/"*
chmod +x "$HOME/HyprArch/configs/hypr/scripts/"*
chmod +x "$HOME/HyprArch/configs/nwg-dock-hyprland/launch.sh"

# Exit on error
set -e

# Ask for sudo password once and keep it alive
echo -e "\e[34mAdministrator password required for installation. Please enter your password:\e[0m"
sudo -v
# Refresh sudo timestamp until script ends
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_REFRESH_PID=$!
trap 'kill $SUDO_REFRESH_PID 2>/dev/null' EXIT

echo "
#---------------------------#
#   Adding repositories     #
#---------------------------#"
echo -e "\e[34mAdding repositories...\e[0m"
bash "$HOME/HyprArch/install_scripts/repos.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31mRepository addition failed. Aborting installation.\e[0m"
    exit 1
fi

echo "
#-------------------------------------------#
#   Updating system and installing packages #
#-------------------------------------------#"
if [ ! -f ~/HyprArch/pkg/pkglist.txt ]; then
    echo -e "\e[31mFile pkglist.txt not found\e[0m"
    exit 1
fi

echo -e "\e[34mUpdating system...\e[0m"
sudo pacman -Syu --needed base-devel --noconfirm --quiet > log.txt || {
    echo -e "\e[31mSystem update error\e[0m"
    exit 1
}

# New block: Checking and installing packages from pkglist.txt rollback
echo -e "\e[34mChecking installed packages...\e[0m"
mapfile -t pkglist < ~/HyprArch/pkg/pkglist.txt
missing_pkgs=()
failed_pkgs=()
for pkg in "${pkglist[@]}"; do
    if ! pacman -Qq "$pkg" &>>log.txt; then
        missing_pkgs+=("$pkg")
    fi
done

if [ ${#missing_pkgs[@]} -eq 0 ]; then
    echo -e "\e[32mAll required packages are already installed.\e[0m"
else
    echo -e "\e[34mInstalling missing packages: ${missing_pkgs[*]}\e[0m"
    for pkg in "${missing_pkgs[@]}"; do
        if sudo pacman -S --noconfirm --needed "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m$pkg installed successfully.\e[0m"
        else
            echo -e "\e[31mError installing $pkg\e[0m"
            failed_pkgs+=("$pkg")
        fi
    done
fi

echo "
#--------------#
#   Backups    #
#--------------#"
if [ ! -f ~/HyprArch/install_scripts/bacups.sh ]; then
    echo -e "\e[31mBackup script not found\e[0m"
    exit 1
fi
if ! bash "$HOME/HyprArch/install_scripts/bacups.sh"; then
    echo -e "\e[31mBackup script execution failed\e[0m"
    exit 1
fi

echo "
#------------------#
#  installing yay  #
#------------------#"
echo -e "\e[34mInstalling yay (AUR)...\e[0m"
bash "$HOME/HyprArch/install_scripts/yay.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31myay installation failed. Aborting installation.\e[0m"
    exit 1
fi

echo "
#-------------------------#
# Installing AUR packages #
#-------------------------#"
if [ ! -f ~/HyprArch/pkg/aur.txt ]; then
    echo -e "\e[31mFile aur.txt not found\e[0m"
    exit 1
fi

echo -e "\e[35mChecking installed AUR packages...\e[0m"
aurlist=($(cat "$HOME/HyprArch/pkg/aur.txt"))
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
    echo -e "\e[32mAlready installed (AUR): ${installed_aur[*]}\e[0m"
fi

if [ ${#missing_aur[@]} -eq 0 ]; then
    echo -e "\e[32mAll required AUR packages are already installed.\e[0m"
else
    echo -e "\e[35mInstalling missing AUR packages...\e[0m"
    for pkg in "${missing_aur[@]}"; do
        echo -e "\e[36m→ Installing (AUR): $pkg\e[0m"
        if yay -S --noconfirm --quiet "$pkg" >>log.txt 2>&1; then
            echo -e "\e[32m$pkg (AUR) installed successfully.\e[0m"
        else
            echo -e "\e[31mError installing $pkg (AUR)\e[0m"
            exit 1
        fi
    done
fi

echo -e "
#-------------------------------------#
# Final check and update of packages  #
#-------------------------------------#"
sudo pacman -Syyuu --noconfirm && yay -Syyuu --noconfirm > log.txt || {
    echo -e "\e[31mFinal package update error\e[0m"
    exit 1
}

echo "
#--------------#
#   Monitor    #
#--------------#"
MONITOR_SCRIPT="$HOME/HyprArch/install_scripts/monitor.sh"
# Checking for the presence of a file
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "Monitor script not found: $MONITOR_SCRIPT"
    exit 1
fi
# Make executable if necessary
chmod +x "$MONITOR_SCRIPT"
# Script launch
echo "Starting monitor setup..."
if ! "$MONITOR_SCRIPT"; then
    echo "Error during execution $MONITOR_SCRIPT"
    exit 1
fi
echo "Monitor setup has been completed successfully."

echo "
#----------------------#
# Configuring services #
#----------------------#"
echo -e "\e[34mConfiguring services...\e[0m"
if systemctl list-units --full | grep -q lightdm; then
    sudo systemctl disable lightdm >>log.txt 2>&1 || {
        echo -e "\e[31mFailed to disable lightdm\e[0m"
        exit 1
    }
fi

for service in bluetooth power-profiles-daemon; do
    if systemctl list-units --full | grep -q "$service"; then
        sudo systemctl enable "$service" >>log.txt 2>&1 || {
            echo -e "\e[31mFailed to configure $service\e[0m"
            exit 1
        }
    else
        echo -e "\e[33mService $service not found, skipping.\e[0m"
    fi
done

sudo systemctl enable sddm >>log.txt 2>&1 || {
    echo -e "\e[31mFailed to configure sddm\e[0m"
    exit 1
}

echo "
#---------------------------#
#  Create base directories  #
#---------------------------#"
LANG=en_US.UTF-8 xdg-user-dirs-update --force

echo "
#---------------------#
#   Shell selection   #
#---------------------#"
echo -e "\e[34mWhich shell do you want to install?\e[0m"
echo -e "\e[36m 1) Keep current shell (default)\e[0m"
echo -e "\e[36m 2) Install fish shell\e[0m"
echo -e "\e[36m 3) Install zsh shell\e[0m"
read -p $'\e[36m Enter your choice [1/2/3]: \e[0m' shell_choice
case "$shell_choice" in
    2)
        echo -e "\e[34mInstalling fish shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/fish.sh"
        if [ $? -ne 0 ]; then
            echo -e "\e[31mFish shell installation failed. Aborting installation.\e[0m"
            exit 1
        fi
        ;;
    3)
        echo -e "\e[34mInstalling zsh shell...\e[0m"
        bash "$HOME/HyprArch/install_scripts/zsh.sh"
        if [ $? -ne 0 ]; then
            echo -e "\e[31mZsh shell installation failed. Aborting installation.\e[0m"
            exit 1
        fi
        ;;
    *)
        echo -e "Keeping current shell. No changes will be made."
        ;;
esac

echo "
#---------------------------#
#   GTK Theme Installation  #
#---------------------------#"
read -p $'\e[36m Install GTK theme? (y/n): \e[0m' install_gtk
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/install_scripts/gtk.sh"
    if [ $? -ne 0 ]; then
        echo -e "\e[31mGTK theme installation failed. Aborting installation.\e[0m"
        exit 1
    fi
fi

echo "
#---------------------------#
#   Copying configurations  #
#---------------------------#"
CONFIGS_DIR="$HOME/HyprArch/configs"
TARGET_DIR="$HOME/.config"
# List of folders to copy
folders=("btop" "cava" "fastfetch" "hypr" "kitty" "nvim" "nwg-dock-hyprland" "nwg-look" "swaync" "Thunar" "waybar" "waypaper" "wlogout" "wofi" "xsettingsd")

if [ -d "$CONFIGS_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    for folder in "${folders[@]}"; do
        target_path="$TARGET_DIR/$folder"
        if [ -d "$target_path" ]; then
            echo -e "\e[33mRemoving $target_path\e[0m"
            rm -rf "$target_path"
        fi
        source_path="$CONFIGS_DIR/$folder"
        if [ -d "$source_path" ]; then
            echo -e "\e[32mCopying $folder to $TARGET_DIR\e[0m"
            cp -r "$source_path" "$TARGET_DIR/"
        else
            echo -e "\e[31mFolder $folder not found in configs\e[0m"
        fi
    done
else
    echo -e "\e[31mConfigs folder not found: $CONFIGS_DIR\e[0m"
fi
rm -f "$HOME/.config/mimeapps.list"
cp "$HOME/HyprArch/configs/mimeapps.list" "$HOME/.config/mimeapps.list"
hyprctl reload 2>/dev/null || echo -e "\e[33mFailed to reload Hyprland configuration. Please restart Hyprland manually.\e[0m"

sleep 2s
max_attempts=5
attempt=0

while true; do
    read -rp "Is everything okay with the screen resolution and interface? (Y/N): " answer
    case "$answer" in
        [Yy])
            echo "Continuing installation..."
            break
            ;;
        *)
            attempt=$((attempt + 1))
            if [ $attempt -ge $max_attempts ]; then
                echo "Installation stopped due to user cancellation."
                exit 1
            else
                echo "Please confirm. Attempts left: $((max_attempts - attempt))"
            fi
            ;;
    esac
done

echo "
#---------------------------#
#   Wallpapers installation #
#---------------------------#"
echo -e "\e[34mInstalling wallpapers...\e[0m"
if bash "$HOME/HyprArch/install_scripts/wallpapers.sh"; then
    echo -e "\e[32mWallpapers installed successfully.\e[0m"
else
    echo -e "\e[31mWallpapers installation failed. Check log.txt for details.\e[0m"
fi

echo "
#---------------------------#
#  Update waybar interface  #
#---------------------------#"
# Determine the active network interface (without loopback)
WAYBAR_DIR="$HOME/.config/waybar"
WAYBAR_IFACE=$(ip route | awk '/default/ {print $5; exit}')

if [ -n "$WAYBAR_IFACE" ]; then
    echo -e "\e[36mDetected interface: $WAYBAR_IFACE\e[0m"

    for cfg in "$WAYBAR_DIR"/config*; do
        [ -f "$cfg" ] || continue
        if grep -q '"interface":' "$cfg"; then
            cp "$cfg" "$cfg.bak"  # Temporary copy in case of failure
            # Replacing the string with the interface
            sed -i "s/\"interface\": \".*\"/\"interface\": \"$WAYBAR_IFACE\"/" "$cfg"
            echo -e "\e[34mUpdated interface in $cfg\e[0m"
            # Delete the temporary .bak file
            rm -f "$HOME/.config/waybar/*.bak"
        fi
    done
    echo -e "\e[32mWaybar config updated to use interface: $WAYBAR_IFACE\e[0m"
else
    echo -e "\e[33mCould not determine network interface. Please check manually.\e[0m"
fi

echo "
#---------------------------#
#  Waybar theme selection   #
#---------------------------#"
echo "Select a Waybar theme:"
echo "1) Dark and White"
echo "2) Blue Arch"
read -p "Enter the topic number (1-2): " choice
case "$choice" in
    1)
        echo "The Dark and White theme is set..."
        if [ -f "$HOME/HyprArch/customs/waybar/dark_and_white/style.css" ]; then
            mkdir -p "$HOME/.config/waybar"  # Ensure the directory exists
            rm -f "$HOME/.config/waybar/style.css"  # Remove existing style.css
            cp "$HOME/HyprArch/customs/waybar/dark_and_white/style.css" "$HOME/.config/waybar/"
        else
            echo -e "\e[31mTheme file not found: $HOME/HyprArch/customs/waybar/dark_and_white/style.css\e[0m"
            exit 1
        fi
        ;;
    2)
        echo "The Blue Arch theme is being installed..."
        if [ -f "$HOME/HyprArch/customs/waybar/blue_arch/style.css" ]; then
            mkdir -p "$HOME/.config/waybar"  # Ensure the directory exists
            rm -f "$HOME/.config/waybar/style.css"  # Remove existing style.css
            cp "$HOME/HyprArch/customs/waybar/blue_arch/style.css" "$HOME/.config/waybar/"
        else
            echo -e "\e[31mTheme file not found: $HOME/HyprArch/customs/waybar/blue_arch/style.css\e[0m"
            exit 1
        fi
        ;;
    *)
        echo "Incorrect selection. Please enter 1 or 2."
        exit 1
        ;;
esac

echo "
#---------------------------#
#   NVIDIA driver setup     #
#---------------------------#"
bash "$HOME/HyprArch/install_scripts/nvidia.sh"

echo "
#-------------------------------#
#   AstroNvim & HyprArch neovim #
#-------------------------------#"
read -p $'\e[36m Install AstroNvim? (y/n): \e[0m' install_astronvim
if [[ "$install_astronvim" =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
fi

echo "
#-----------------#
# BlackArch utils #
#-----------------#"
echo -e "\e[34mInstalling BlackArch tools...\e[0m"
read -p $'\e[36mDo you want to install BlackArch tools? (y/n): \e[0m' install_blackarch
if [[ "$install_blackarch" =~ ^[Yy]$ ]]; then
    echo -e "\e[34m🔧 Starting BlackArch installation...\e[0m"
    bash "$HOME/HyprArch/install_scripts/blackarch.sh"
    if [ $? -ne 0 ]; then
        echo -e "\e[31mBlackArch installation failed. Aborting installation.\e[0m"
        exit 1
    fi
else
    echo -e "\e[33mBlackArch installation skipped.\e[0m"
fi

echo "
#-------------#
#    sddm     #
#-------------#"
echo -e "\e[34mConfiguring SDDM...\e[0m"
bash "$HOME/HyprArch/install_scripts/sddm.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31mSDDM configuration failed. Aborting installation.\e[0m"
    exit 1
fi

echo "
#--------------#
#     grub     #
#--------------#"
echo -e "\e[34mConfiguring GRUB...\e[0m"
bash "$HOME/HyprArch/install_scripts/grub.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31mGRUB configuration failed. Aborting installation.\e[0m"
    exit 1
fi

echo "
#---------------------------#
#   Install more programs   #
#---------------------------#"
echo -e "\e[34mInstall more programs...\e[0m"
bash "$HOME/HyprArch/install_scripts/programms.sh"
if [ $? -ne 0 ]; then
    echo -e "\e[31mInstall more programs failed. Aborting installation.\e[0m"
    exit 1
fi

echo "
#------------------------------#
#   HyprVSCode custom install  #
#------------------------------#"
if pacman -Q visual-studio-code-bin &>/dev/null; then
	if bash "$HOME/HyprArch/install_scripts/vs-code.sh"; then
		echo -e "\e[32mHyprVSCode custom installed successfully!\e[0m"
	else
		echo -e "\e[31mError installing HyprVSCode custom!\e[0m"
	fi
else
	echo -e "\e[33mVS-Code is not installed, skipping custom install\e[0m"
fi

echo "
#---------------------------------#
#   Going to HyprArch directory   #
#---------------------------------#"
cd $HOME/HyprArch

echo -e "\e[32mInstallation completed successfully!\e[0m"
read -p $'\e[36mWould you like to reboot now? (Y/n): \e[0m' reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo -e "\e[34mRebooting...\e[0m"
    sudo reboot
else
    echo -e "\e[34mInstallation completed. You can reboot later.\e[0m"
    echo -e "\e[34mPlease reboot your system to apply all changes.\e[0m"
    echo -e "\e[34mThank you for installing HyprArch!\e[0m"
    echo -e "\e[34mFor more information, visit: https://hyprarch.ru\e[0m"
    echo -e "\e[34mIf you have any questions, please contact us on Telegram: https://t.me/hyprarch\e[0m"
    exit 0
fi
