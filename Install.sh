#!/bin/bash
set -e
#######################
#	Colors
########################
R="\e[31m"
G="\e[32m"
B="\e[34m"
Y="\e[33m"
W="\e[37m"
E="\e[0m"
#
log(){  printf "${W}%s\n" "$*"; }
info(){ printf "${B}%s\n" "$*"; }
ok(){   printf "${G}%s\n" "$*"; }
warn(){ printf "${Y}%s\n" "$*"; }
err(){  printf "${R}%s\n" "$*" >&2; }
############################
clear
info "
  //////////////////////////////////
 // HyprArch installation script //
//////////////////////////////////"
############################
############################


############################
#	1. Network
############################
log "
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
sleep 1s
#################################


############################
#	2. Activate scripts
#############################
log "
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
sleep 1s
#################################


############################
#	3. Sudo password
############################
log "
###################
## Sudo password ##
###################"
info "Administrator password required for installation. Please enter your password:"
sudo -v
ok "Password accepted"
#################################
sleep 1s
#################################


#################################
#	4. Add multilib repository
##################################
log "
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
sleep 1s
#################################


#######################
#	5. Update system
#######################
log "
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
sleep 1s
#################################


#######################
#	6. Backup
#######################
log "
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
sleep 1s
#################################


#######################################
#   7. Installing the necessary packages
########################################
log "
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
sleep 1s
#################################


##########################
#  8. Set main monitor
###########################
log "
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
sleep 1s
#################################


######################################
#  9. Creating standard directories
#######################################
log "
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
sleep 1s
#################################


#################################
#  10. Choosing the main shell
#################################
log "
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
sleep 1s
#################################


#####################################
#  11. Configuring system services
#####################################
log "
###################################
##  Configuring system services  ##
###################################"
bash "$HOME/HyprArch/scripts/services.sh"
#################################
sleep 1s
#################################


#########################################
#  12. Installing and configuring themes
##########################################
log "
#########################################
##  Installing and configuring themes  ##
#########################################"
read -p $'\e[34mInstall GTK and icon theme? (y/n): \e[0m' install_theme
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/scripts/themes.sh"
    if [ $? -ne 0 ]; then
        err "Theme installation failed. Aborting installation"
        exit 1
    fi
fi
#################################
sleep 1s
#################################


###################################################################
#  13. Selecting a theme for Waybar, Rofi, and Nwg-dock-hyprland
###################################################################
log "
#################################################################
##  Selecting a theme for waybar, rofi, and nwg-dock-hyprland  ##
#################################################################"
bash "$HOME/HyprArch/scripts/theme_switcher.sh"
#################################
sleep 1s
#################################


################################
#  14. Copying configurations
################################
log "
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
log "
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
log "
############################################
##  Detect GPU and install proper drivers ##
############################################"
bash "$HOME/HyprArch/scripts/gpu.sh"
#################################
sleep 1s
#################################


###############################
#  17. Replace /etc/os-release
###############################
log "
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
log "
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
log "
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
log "
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
log "
##################################################
##  Adding the BlackArch repository (optional)  ##
##################################################"
bash "$HOME/HyprArch/scripts/blackarch.sh"
#################################
sleep 1s
#################################


read -rp "Do you want to restore repository configs and customs to their original state? [y/N]: " answer
case "$answer" in
    [Yy]* )
        info "Restoring repository configs and customs..."
        cd "$HOME/HyprArch"
        git restore configs customs
        ok "Repository configs and customs restored."
        ;;
    * )
        warn "Skipping repository restore."
        ;;
esac

info "
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
