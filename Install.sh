#!/bin/bash

# ==================================================================================
# HyprArch Installation Script
#
# This script automates the installation and configuration of the HyprArch environment.
# It handles network checks, package installation, configuration deployment, and more.
# ==================================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# ==================================================================================
#                             CONFIGURATION
# ==================================================================================
# Define all script paths and directories here for easy maintenance.
HYPRARCH_DIR="$HOME/HyprArch"
SCRIPTS_DIR="$HYPRARCH_DIR/scripts"
CUSTOM_HYPR_SCRIPTS_DIR="$HYPRARCH_DIR/customs/hypr/scripts"
NWGDOCK_LAUNCHER="$HYPRARCH_DIR/configs/nwg-dock-hyprland/launch.sh"
PACMAN_PKG_LIST="$HYPRARCH_DIR/pkg/pkglist.txt"
YAY_PKG_LIST="$HYPRARCH_DIR/pkg/yay.txt"

# ==================================================================================
#               COLOR DEFINITIONS & LOGGING FUNCTIONS
# ==================================================================================
# This block provides color variables and helper functions for
# printing color-coded status messages to the terminal.

# --- COLOR DEFINITIONS ---
RESET='\e[0m'
BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
B_BLACK='\e[1;30m'
B_RED='\e[1;31m'
B_GREEN='\e[1;32m'
B_YELLOW='\e[1;33m'
B_BLUE='\e[1;34m'
B_MAGENTA='\e[1;35m'
B_CYAN='\e[1;36m'
B_WHITE='\e[1;37m'
# --- LOGGING FUNCTIONS ---
log() { printf "${WHITE}%s\n${RESET}" "$*"; }
info() { printf "${BLUE}%s\n${RESET}" "$*"; }
ok() { printf "${GREEN}%s\n${RESET}" "$*"; }
warn() { printf "${YELLOW}%s\n${RESET}" "$*"; }
err() { printf "${RED}%s\n${RESET}" "$*" >&2; }
prompt() { printf "${B_YELLOW}%s${RESET}" "$*"; }
header() { printf "\n${B_MAGENTA}##################################################\n## %s\n##################################################${RESET}\n" "$@"; }

# ==================================================================================
#                             HELPER FUNCTIONS
# ==================================================================================

# A standardized function for asking Yes/No questions.
# Usage: if ask_yes_no "Do you want to proceed?"; then ...
ask_yes_no() {
    local question=$1
    local default=${2:-N}
    local answer

    while true; do
        if [[ "$default" == "Y" ]]; then
            read -rp "$(prompt "$question [Y/n]: ")" answer
            answer=${answer:-Y}
        else
            read -rp "$(prompt "$question [y/N]: ")" answer
            answer=${answer:-N}
        fi
        case "$answer" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) warn "Invalid input. Please enter 'y' or 'n'." ;;
        esac
    done
}

# A wrapper to run external scripts and handle errors automatically.
# Usage: run_script "/path/to/script.sh" "Failed to run the script."
run_script() {
    local script_path=$1
    local error_message=${2:-"Execution failed for script: $script_path"}
    if [ ! -f "$script_path" ]; then
        err "Script not found: $script_path"
        exit 1
    fi
    chmod +x "$script_path"
    if bash "$script_path"; then
        ok "Script executed successfully: $script_path"
    else
        err "$error_message"
        exit 1
    fi
}

# ==================================================================================
#                             CORE LOGIC FUNCTIONS
# ==================================================================================

# 1. Network Check
check_network() {
    header "1. Checking Network Connection"
    while ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; do
        err "Internet connection is not available."
        info "Select an option:"
        echo -e "  ${CYAN}1)${RESET} Open nmtui to configure network"
        echo -e "  ${CYAN}2)${RESET} Check again"
        echo -e "  ${CYAN}3)${RESET} Exit"
        read -rp "$(prompt "Your choice [1/2/3]: ")" choice

        case "$choice" in
            1) nmtui ;;
            2) continue ;;
            3) err "Aborting installation."; exit 1 ;;
            *) err "Invalid choice." ;;
        esac
    done
    ok "Network connection is available."

    WAYBAR_DIR="$HOME/HyprArch/configs/waybar"
    WAYBAR_IFACE=$(ip route | awk '/default/ {print $5; exit}')
    if [ -z "$WAYBAR_IFACE" ]; then
        err "Could not determine network interface. Please check manually."
        exit 1
    fi
    info "Detected interface: $WAYBAR_IFACE"
    for cfg in "$WAYBAR_DIR"/config*; do
        if [ ! -f "$cfg" ]; then
            continue
        fi
        if grep -q '"interface":' "$cfg"; then
            TEMP_FILE=$(mktemp)
            sed "s/\"interface\": \".*\"/\"interface\": \"$WAYBAR_IFACE\"/" "$cfg" > "$TEMP_FILE"
            if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
                mv "$TEMP_FILE" "$cfg"
                info "Successfully updated interface in $cfg"
            else
                rm -f "$TEMP_FILE"
                err "Failed to update interface in $cfg. Original file remains unchanged."
            fi
        else
            info "Skipping $cfg: No 'interface' key found."
        fi
    done
    info "Waybar configuration update complete."
}

# 2. Activate Scripts
activate_scripts() {
    header "2. Activating Scripts"
    local targets=("$SCRIPTS_DIR/"* "$CUSTOM_HYPR_SCRIPTS_DIR/"* "$NWGDOCK_LAUNCHER")
    for target in "${targets[@]}"; do
        if [ -e "$target" ]; then
            chmod +x "$target"
            log "Made executable: $target"
        else
            warn "Not found, skipping: $target"
        fi
    done
    ok "Permissions set successfully."
}

# 4. Add Multilib Repository
add_multilib() {
    header "4. Adding Multilib Repository"
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        ok "Multilib repository is already enabled."
        return
    fi

    info "Adding multilib repository..."
    if echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null; then
        ok "Multilib repository added successfully."
    else
        err "Failed to add multilib repository. Aborting."
        exit 1
    fi
}

# 5. Update System
update_system() {
    header "5. Updating System"
    info "Updating pacman repositories and system..."
    sudo pacman -Syyu --noconfirm
    if command -v yay >/dev/null 2>&1; then
        info "Found yay, updating AUR packages..."
        yay -Syyu --noconfirm || warn "Warning: yay update failed, continuing..."
    else
        warn "yay not found. It will be installed later if needed."
    fi
    ok "System update complete."
}

# 7. Install Packages
install_system_packages() {
    header "7. Installing Necessary Packages"

    # Check if yay is installed
    if ! command -v yay >/dev/null 2>&1; then
        info "yay is not installed. Installing it now..."
        sudo pacman -S --noconfirm --needed git go
        cd "$HOME"
        if git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm; then
            ok "yay installed successfully."
            cd "$HOME"
            rm -rf "$HOME/yay"
        else
            err "Failed to install yay. Aborting."
            cd "$HOME"
            rm -rf "$HOME/yay"
            exit 1
        fi
    fi

    # Combine package lists and find out which packages are missing
    mapfile -t pacman_pkgs < <(grep -vE '^\s*($|#)' "$PACMAN_PKG_LIST")
    mapfile -t yay_pkgs < <(grep -vE '^\s*($|#)' "$YAY_PKG_LIST")

    # Check pacman packages
    info "Checking pacman packages..."
    pacman_missing=()
    for pkg in "${pacman_pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            pacman_missing+=("$pkg")
        fi
    done

    if [ ${#pacman_missing[@]} -gt 0 ]; then
        info "Installing ${#pacman_missing[@]} missing packages with pacman..."
        sudo pacman -S --noconfirm --needed "${pacman_missing[@]}" || err "Some pacman packages failed to install. Please check the log."
    else
        ok "All pacman packages are already installed."
    fi

    # Check yay packages
    info "Checking AUR packages..."
    yay_missing=()
    for pkg in "${yay_pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            yay_missing+=("$pkg")
        fi
    done

    if [ ${#yay_missing[@]} -gt 0 ]; then
        info "Installing ${#yay_missing[@]} missing packages with yay..."
        yay -S --noconfirm --needed "${yay_missing[@]}" || warn "Some AUR packages failed to install. Continuing..."
    else
        ok "All AUR packages are already installed."
    fi

    ok "All package installations completed."
}


# 10. Choose Shell
choose_shell() {
    header "10. Choosing the Main Shell"
    info "Which shell do you want to install as default?"
    echo -e "  ${CYAN}0)${RESET} Keep current shell (skip)"
    echo -e "  ${CYAN}1)${RESET} Install and configure fish"
    echo -e "  ${CYAN}2)${RESET} Install and configure zsh"
    read -rp "$(prompt "Enter your choice [0/1/2]: ")" shell_choice

    case "$shell_choice" in
        1)
            info "Installing fish shell..."
            run_script "$SCRIPTS_DIR/fish.sh" "Fish shell installation failed. Aborting."
            ;;
        2)
            info "Installing zsh shell..."
            run_script "$SCRIPTS_DIR/zsh.sh" "Zsh shell installation failed. Aborting."
            ;;
        *)
            warn "Keeping current shell. No changes will be made."
            ;;
    esac
}

# ==================================================================================
#                                 MAIN SCRIPT
# ==================================================================================

main() {
    clear
    info "
        /////////////////////////////////////////////////////
       //////                                         //////
      ///         HYPRARCH INSTALLATION SCRIPT          ///
     //////                                         //////
    /////////////////////////////////////////////////////
    "

    # Step 1: Network
    check_network
    sleep 1

    # Step 2: Activate scripts
    activate_scripts
    sleep 1

    # Step 3: Sudo password
    header "3. Acquiring Sudo Privileges"
    info "Administrator password required for installation. Please enter your password:"
    sudo -v
    ok "Password accepted. Privileges will be kept for the duration of the script."
    sleep 1

    # Step 4: Add multilib
    add_multilib
    sleep 1

    # Step 5: Update system
    update_system
    sleep 1

    # Step 6: Backup
    header "6. Running Backup Script"
    run_script "$SCRIPTS_DIR/backup.sh" "Backup failed. Aborting."
    sleep 1

    # Step 7: Install packages
    install_system_packages
    sleep 1

    # Step 8: Set main monitor
    header "8. Set Main Monitor"
    if ask_yes_no "Do you want to configure the main monitor now?"; then
        run_script "$SCRIPTS_DIR/monitor.sh" "Error during monitor setup."
    else
        warn "Skipping monitor configuration."
    fi
    sleep 1

    # Step 9: Create standard directories
    header "9. Creating Standard XDG Directories"
    if ask_yes_no "Do you want to update XDG user directories?"; then
        LANG=en_US.UTF-8 xdg-user-dirs-update --force
        ok "Successfully updated XDG user directories."
    else
        warn "Skipping XDG user directories update."
    fi
    sleep 1

    # Step 10: Choose shell
    choose_shell
    sleep 1

    # Step 11: Configure services
    header "11. Configuring System Services"
    run_script "$SCRIPTS_DIR/services.sh" "Failed to configure services."
    sleep 1

    # Step 12: Install themes
    header "12. Installing and Configuring Themes"
    if ask_yes_no "Install GTK and icon theme?"; then
        run_script "$SCRIPTS_DIR/themes.sh" "Theme installation failed."
    fi
    sleep 1

    # Step 13: Select UI Theme
    header "13. Selecting a Theme for Waybar, Rofi, etc."
    run_script "$SCRIPTS_DIR/theme_switcher.sh" "Theme selection script failed."
    sleep 1

    # Step 14: Copy configurations
    header "14. Copying Configurations"
    run_script "$SCRIPTS_DIR/configs.sh" "Failed to copy configurations."
    sleep 1

    # Step 15: Configure SDDM and GRUB
    header "15. Configuring SDDM and GRUB"
    if ask_yes_no "Do you want to install HyprArch themes for SDDM and GRUB?"; then
        run_script "$SCRIPTS_DIR/sddm.sh" "SDDM configuration failed."
        run_script "$SCRIPTS_DIR/grub.sh" "GRUB configuration failed."
        ok "SDDM & GRUB configured successfully."
    else
        warn "Skipping SDDM & GRUB theme installation."
    fi
    sleep 1

    # Step 16: GPU Drivers
    header "16. Detect GPU and Install Drivers"
    run_script "$SCRIPTS_DIR/gpu.sh" "GPU driver installation failed."
    sleep 1

    # Step 17: Replace os-release
    header "17. Customizing /etc/os-release"
    sudo bash "$SCRIPTS_DIR/os.sh"
    ok "/etc/os-release updated."
    sleep 1

    # Step 18: Wallpapers
    header "18. Installing Wallpapers"
    run_script "$SCRIPTS_DIR/wallpapers.sh" "Wallpaper installation failed."
    sleep 1

    # Step 19: Editors
    header "19. Selecting Terminal Text Editor"
    sudo bash "$SCRIPTS_DIR/editors.sh"
    ok "Editor selection script finished."
    sleep 1

    # Step 20: CLI Utils
    header "20. Installing CLI Utils"
    run_script "$SCRIPTS_DIR/utils.sh" "Failed to install CLI Utils."
    sleep 1

    # Step 21: Additional programs
    header "21. Installing Additional Programs"
    run_script "$SCRIPTS_DIR/programms.sh" "Failed to install additional programs."
    sleep 1

    # Step 22: BlackArch repository
    header "22. Adding BlackArch Repository (Optional)"
    run_script "$SCRIPTS_DIR/blackarch.sh" "Failed to run BlackArch script."
    sleep 1

    # Final step: Restore repo state
    if ask_yes_no "Do you want to restore repository configs and customs to their original state?"; then
        info "Restoring repository configs and customs..."
        cd "$HYPRARCH_DIR"
        git restore configs customs
        ok "Repository configs and customs restored."
    else
        warn "Skipping repository restore."
    fi

    # Completion Message
    info "
      ////////////////////////////////////////////
     //  Installation completed successfully!  //
    ////////////////////////////////////////////"
    echo
    echo
    if ask_yes_no "Would you like to reboot now?" Y; then
        info "Rebooting the system in 3 seconds..."
        sleep 3
        sudo reboot
    else
        warn "Please reboot your system to apply all changes."
        echo
        info "====================[ HyprArch Installed ]===================="
        echo
        echo -e "   ${GREEN}✔ Your system is ready."
        echo -e "   ${YELLOW}➜ Reboot is recommended before first login."
        echo
        echo -e "   ${CYAN}Official website: ${BLUE}https://hyprarch.ru"
        echo -e "   ${CYAN}Community chat:   ${BLUE}https://t.me/hyprarch"
        info "=============================================================="
        echo
    fi
    exit 0
}

# Run the main function of the script
main
