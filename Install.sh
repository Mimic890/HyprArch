#!/bin/bash
set -e
#######################
#	Colors
########################
R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
E="\e[0m"
#
info(){ printf "${B}%s\n" "$*"; }
ok(){   printf "${G}%s\n" "$*"; }
warn(){ printf "${Y}%s\n" "$*"; }
err(){  printf "${R}%s\n" "$*" >&2; }
############################
clear
echo "  //////////////////////////////////
 // HyprArch installation script //
//////////////////////////////////"
############################
############################


############################
#	1. Network
############################
echo "
#################################
## Checking Network connection ##
#################################"
check_connection() {
    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        ok "Internet connection is available"
        return 0
    else
        err "Internet connection is not available"
        return 1
    fi
}
while true; do
    if check_connection; then
        break
    else
        echo
        info "Select an option: "
        ok "  0) Open nmtui"
        warn "  1) Check again"
        err "  2) Exit"
        read -rp "$(warn "Your choice: ")" choice
        case "$choice" in
            1)
                nmtui
                ;;
            2)
                continue
                ;;
            3)
                exit 1
                ;;
            *)
                err "Invalid choice"
                ;;
        esac
    fi
done
ok "Network check successful"
#################################
sleep 0.5s
#################################


############################
#	2. Activate scripts
#############################
echo "
########################
##  Activate scripts  ##
########################"
make_executable() {
    for target in "$@"; do
        if [ -e "$target" ]; then
            chmod +x "$target"
            ok "Made executable: $target"
        else
            err "Not found: $target"
        fi
    done
}
make_executable "$HOME/HyprArch/scripts/"* "$HOME/HyprArch/customs/hypr/scripts/"* "$HOME/HyprArch/configs/nwg-dock-hyprland/launch.sh"
ok "Permissions set successfully"
#################################
sleep 0.5s
#################################


############################
#	3. Sudo password
#############################
echo "
###################
## Sudo password ##
###################"
info "Administrator password required for installation. Please enter your password:"
sudo -v
ok "Password accepted"
#################################
sleep 0.5s
#################################


#################################
#	4. Add multilib repository
##################################
echo "
###############################
##  Add multilib repository  ##
###############################"
info "Adding repositories..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    if echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null; then
        ok "Multilib repository added successfully"
    else
        err "Failed to add multilib repository. Aborting installation"
        exit 1
    fi
else
    ok "Multilib repository is already enabled"
fi
#################################
sleep 0.5s
#################################


#######################
#	5. Update system
#######################
echo "
#######################
##  Updating system  ##
#######################"
sudo pacman -Syyuu
if command -v yay >/dev/null 2>&1; then
    info "Found yay, updating yay..."
    yay -Syyuu || err "Warning: yay update failed, continuing..."
    yay_installed=true
else
    warn "yay not found"
    yay_installed=false
fi
ok "System update complete"
#################################
sleep 0.5s
#################################


#######################
#	6. Backup
#######################
echo "
###############################
##  Running backup script    ##
###############################"
backup_script="$HOME/HyprArch/scripts/backup.sh"
if [ -x "$backup_script" ]; then
    "$backup_script"
    ok "Backup completed successfully"
else
    err "Backup script not found or not executable: $backup_script"
    exit 1
fi
#################################
sleep 0.5s
#################################


#######################################
#   7. Installing the necessary packages
########################################
echo "
#########################################
##  Installing the necessary packages  ##
#########################################"
install_packages() {
    local manager=$1
    local pkgfile=$2
    local skip_pkgs=("${!3}")
    local missing=()
    if [ ! -f "$pkgfile" ]; then
        err "Package list file not found: $pkgfile"
        exit 1
    fi
    mapfile -t pkgs < <(grep -vE '^\s*($|#)' "$pkgfile")
    for pkg in "${pkgs[@]}"; do
        if [[ " ${skip_pkgs[*]} " == *" $pkg "* ]]; then
            warn "Skipping package $pkg as instructed"
            continue
        fi
        if ! pacman -Qi "$pkg" >/dev/null 2>&1 && ! yay -Qi "$pkg" >/dev/null 2>&1; then
            info "Installing $pkg via $manager..."
            if ! $manager -S --noconfirm "$pkg"; then
                missing+=("$pkg")
            fi
        else
            ok "$pkg is already installed"
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        err "The following packages failed to install via $manager:"
        for p in "${missing[@]}"; do
            err "  - $p"
        done
    else
        ok "All $manager packages installed successfully"
    fi
}
if [ "$yay_installed" = false ]; then
    skip_yay_pkg=("yay")
else
    skip_yay_pkg=()
fi
install_packages "sudo pacman" "$HOME/HyprArch/pkg/pkglist.txt" skip_yay_pkg[@]
if [ "$yay_installed" = false ]; then
    info "Installing yay manually because it was not found..."
    cd "$HOME" && git clone https://aur.archlinux.org/yay.git
    cd "$HOME/yay"
    makepkg -si --noconfirm || err "Warning: yay installation failed, continuing..."
    cd "$HOME"
    rm -rf "$HOME/yay"
    yay_installed=true
    ok "yay installed successfully"
    info "Update yay"
    yay -Syyuu || err "Warning: yay update failed, continuing..."
fi

install_packages "yay" "$HOME/HyprArch/pkg/yay.txt" skip_yay_pkg[@] || \
    err "Warning: Package installation via yay failed, continuing..."

ok "All package installations completed"
#################################
sleep 0.5s
#################################


##########################
#  8. Set main monitor
###########################
echo "
########################
##  Set main monitor  ##
########################"
read -rp "Do you want to configure the main monitor now? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    MONITOR_SCRIPT="$HOME/HyprArch/scripts/monitor.sh"
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        err "Monitor script not found: $MONITOR_SCRIPT"
        exit 1
    fi
    chmod +x "$MONITOR_SCRIPT"
    if ! "$MONITOR_SCRIPT"; then
        err "Error during execution $MONITOR_SCRIPT"
        exit 1
    fi
    ok "Monitor setup has been completed successfully"
else
    warn "Skipping monitor configuration"
fi
#################################
sleep 0.5s
#################################


######################################
#  9. Creating standard directories
#######################################
echo "
#####################################
##  Creating standard directories  ##
#####################################"
read -rp "Do you want to update XDG user directories? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    LANG=en_US.UTF-8 xdg-user-dirs-update --force
    ok "Successfully updated XDG user directories"
else
    warn "Skipping XDG user directories update"
fi
#################################
sleep 0.5s
#################################


#################################
#  10. Choosing the main shell
#################################
echo "
###############################
##  Choosing the main shell  ##
###############################"
info "Which shell do you want to install?"
ok " 0) Keep current shell (skip)"
ok " 1) Install fish shell"
ok " 2) Install zsh shell"
read -p $'\e[34m Enter your choice [0/1/2]: \e[0m' shell_choice
case "$shell_choice" in
    2)
        info "Installing fish shell..."
        bash "$HOME/HyprArch/scripts/fish.sh"
        if [ $? -ne 0 ]; then
            err "Fish shell installation failed. Aborting installation"
            exit 1
        fi
        ;;
    3)
        info "Installing zsh shell..."
        bash "$HOME/HyprArch/scripts/zsh.sh"
        if [ $? -ne 0 ]; then
            err "Zsh shell installation failed. Aborting installation"
            exit 1
        fi
        ;;
    *)
        warn "Keeping current shell. No changes will be made"
        ;;
esac
#################################
sleep 0.5s
#################################


#####################################
#  11. Configuring system services
#####################################
echo "
###################################
##  Configuring system services  ##
###################################"
bash "$HOME/HyprArch/scripts/services.sh"
#################################
sleep 0.5s
#################################


#########################################
#  12. Installing and configuring themes
##########################################
echo "
#########################################
##  Installing and configuring themes  ##
#########################################"
read -p $'\e[34mInstall GTK theme? (y/n): \e[0m' install_gtk
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/scripts/themes.sh"
    if [ $? -ne 0 ]; then
        err "Theme installation failed. Aborting installation"
        exit 1
    fi
fi
#################################
sleep 0.5s
#################################


###################################################################
#  13. Selecting a theme for Waybar, Rofi, and Nwg-dock-hyprland
###################################################################
echo "
#################################################################
##  Selecting a theme for waybar, rofi, and nwg-dock-hyprland  ##
#################################################################"
CUSTOMS_DIR="$HOME/HyprArch/customs"
WAYBAR_DIR="$HOME/.config/waybar"
ROFI_DIR="$HOME/.config/rofi"
DOCK_DIR="$HOME/.config/nwg-dock-hyprland"

THEMES=("blue_arch" "black_arch" "white_arch" "amoled_arch" "purple_arch" "orange_arch")

info "Available themes:"
warn "0) Skip theme setup"
for i in "${!THEMES[@]}"; do
    info "$((i+1))) ${THEMES[i]}"
done

read -p "Enter the number of your choice: " choice

if [[ "$choice" == "0" ]]; then
    warn "Skipping theme setup..."
else
    THEME_NAME="${THEMES[$((choice-1))]}"
    if [[ -z "$THEME_NAME" ]]; then
        err "Invalid choice. Exiting."
        exit 1
    fi
    ok "Selected theme: $THEME_NAME"

    # --- Waybar ---
    info "Applying theme for Waybar..."
    [ -d "$WAYBAR_DIR" ] && rm -rf "$WAYBAR_DIR"
    mkdir -p "$WAYBAR_DIR"
    cp "$CUSTOMS_DIR/waybar/${THEME_NAME}.css" "$WAYBAR_DIR/style.css"

    # --- Rofi ---
    info "Applying theme for Rofi..."
    [ -d "$ROFI_DIR" ] && rm -rf "$ROFI_DIR"
    mkdir -p "$ROFI_DIR"
    cp "$CUSTOMS_DIR/rofi/${THEME_NAME}.rasi" "$ROFI_DIR/config.rasi"

    # --- Dock ---
    info "Applying theme for nwg-dock-hyprland..."
    [ -d "$DOCK_DIR" ] && rm -rf "$DOCK_DIR"
    mkdir -p "$DOCK_DIR"
    cp "$CUSTOMS_DIR/nwg-dock-hyprland/${THEME_NAME}.css" "$DOCK_DIR/style.css"

    ok "Theme applied successfully for all components!"
fi
#################################
sleep 1s
#################################


################################
#  14. Copying configurations
################################
echo "
##############################
##  Copying configurations  ##
##############################"
bash "$HOME/HyprArch/scripts/configs.sh"
#################################
sleep 1s
#################################


####################################
#  15. Configuring SDDM and GRUB
####################################
echo "
#################################
##  Configuring SDDM and GRUB  ##
#################################"
read -rp "Do you want to install HyprArch themes for SDDM and GRUB? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    if bash "$HOME/HyprArch/scripts/sddm.sh"; then
        ok "SDDM configured successfully"
    else
        err "SDDM configuration failed. Aborting."
        exit 1
    fi

    if bash "$HOME/HyprArch/scripts/grub.sh"; then
        ok "GRUB configured successfully"
    else
        err "GRUB configuration failed. Aborting."
        exit 1
    fi

    ok "SDDM & GRUB configured successfully"
else
    warn "Skipping SDDM & GRUB theme installation"
fi
#################################
sleep 1s
#################################


###############################################
#  16. Detect GPU and install proper drivers
###############################################
echo "
############################################
##  Detect GPU and install proper drivers ##
############################################"
bash "$HOME/scripts/gpu.sh"
#################################
sleep 1s
#################################


###############################
#  17. Replace /etc/os-release
###############################
echo "
###############################
##  Replace /etc/os-release  ##
###############################"
sudo bash "$HOME/HyprArch/scripts/os.sh"
#################################
sleep 1s
#################################


###############################
#  18. Wallpapers installation
###############################
echo "
##############################
##  Wallpaper installation  ##
##############################"
bash "$HOME/HyprArch/scripts/wallpapers.sh"
#################################
sleep 1s
#################################


#################################################
#  19. Selecting a text editors in the terminal
#################################################
echo "
###############################################
##  Selecting a text editor in the terminal  ##
###############################################"
sudo bash "$HOME/HyprArch/scripts/editors.sh"
#################################
sleep 1s
#################################


#####################################
#  20. Installing additional programs
#####################################
echo "
######################################
##  Installing additional programs  ##
######################################"
bash "$HOME/HyprArch/scripts/programms.sh"
#################################
sleep 1s
#################################

######################################################
#  21. Adding the BlackArch repository (optional)
######################################################
echo "
##################################################
##  Adding the BlackArch repository (optional)  ##
##################################################"
bash "$HOME/HyprArch/scripts/blackarch.sh"
#################################
sleep 1s
#################################



echo "
  ////////////////////////////////////////////
 //  Installation completed successfully!  //
////////////////////////////////////////////"

echo
read -rp "$(printf "${Y}Would you like to reboot now? (Y/n): ")" reboot_choice
echo

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    info "Rebooting the system..."
    sleep 2
    sudo reboot
else
    info "Installation completed successfully!"
    warn "Please reboot your system to apply all changes."

    echo
    info "====================[ HyprArch Installed ]===================="
    echo -e "   ${G}✔ Your system is ready."
    echo -e "   ${Y}➜ Reboot is recommended before first login."
    echo
    echo -e "   ${C}Official website: ${B}https://hyprarch.ru"
    echo -e "   ${C}Community chat:   ${B}https://t.me/hyprarch"
    echo
    info "============================================================="
    echo
    exit 0
fi
