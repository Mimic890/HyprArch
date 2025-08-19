#!/bin/bash
# ===================================================================
# THEME SWITCHER SCRIPT (WITH COLORS)
# ===================================================================
# This script allows you to select a theme from a list and apply it
# to specified applications. It uses color-coded output for clarity.
# ===================================================================
# --- COLOR DEFINITIONS ---
# Defines standard and bold ANSI color escape codes.
# Reset all text attributes
RESET='\e[0m'
# Regular Colors
BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
# Bold Colors
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
# --- CONFIGURATION ---
THEME_SOURCE_DIR="$HOME/HyprArch/customs"
CONFIG_DIR="$HOME/HyprArch/configs"
declare -a themes=("blue_arch" "black_arch" "white_arch" "amoled_arch" "purple_arch" "orange_arch")
# --- FUNCTIONS ---
show_all_colors() {
    log "--- Standard Colors ---"
    printf "${BLACK}Black ${RED}Red ${GREEN}Green ${YELLOW}Yellow ${BLUE}Blue ${MAGENTA}Magenta ${CYAN}Cyan ${WHITE}White\n${RESET}"
    log "--- Bold Colors ---"
    printf "${B_BLACK}Black ${B_RED}Red ${B_GREEN}Green ${B_YELLOW}Yellow ${B_BLUE}Blue ${B_MAGENTA}Magenta ${B_CYAN}Cyan ${B_WHITE}White\n\n${RESET}"
}
show_theme_menu() {
    log "Please select a theme to apply:"
    echo -e "${WHITE}------------------------------------------${RESET}"
    for i in "${!themes[@]}"; do
        printf " ${B_CYAN}%d)${RESET} ${themes[$i]}\n" "$((i+1))"
    done
    printf " ${B_CYAN}0)${RESET} Skip\n"
    echo -e "${WHITE}------------------------------------------${RESET}"
}
apply_theme() {
    local app_name=$1
    local dest_dir=$2
    local style_file=$3
    local theme_ext=$4
    local selected_theme=$5
    local source_file="$THEME_SOURCE_DIR/$app_name/${selected_theme}.${theme_ext}"
    local dest_file="$dest_dir/$style_file"
    printf "\n${B_WHITE}Applying theme for: ${CYAN}%s${RESET}\n" "$app_name"
    if [[ ! -f "$source_file" ]]; then
        warn "   - Warning: Theme file not found at $source_file. Skipping."
        return
    fi
    if [[ -f "$dest_file" ]]; then
        rm -f "$dest_file"
        log "   - Removed old style: $dest_file"
    fi
    mkdir -p "$dest_dir"
    cp "$source_file" "$dest_file"
    ok "   - Copied new style: $source_file -> $dest_file"
}
# --- MAIN SCRIPT ---
show_theme_menu
read -p "$(printf "${B_YELLOW}Enter number (0-%d): ${RESET}" $((${#themes[@]})))" choice
if [[ "$choice" -eq 0 ]]; then
    info "\nSkipping theme change. The script will now continue..."
    exit 0
fi
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#themes[@]} ]]; then
    err "\nError: Invalid selection. Please run the script again and select a correct number."
    exit 1
fi
selected_theme=${themes[$((choice-1))]}
printf "\n${B_GREEN}Selected theme: %s. Applying...${RESET}\n" "$selected_theme"
apply_theme "waybar" "$CONFIG_DIR/waybar" "style.css" "css" "$selected_theme"
apply_theme "rofi" "$CONFIG_DIR/rofi" "theme.rasi" "rasi" "$selected_theme"
apply_theme "nwg-dock-hyprland" "$CONFIG_DIR/nwg-dock-hyprland" "style.css" "css" "$selected_theme"
ok "All themes have been applied successfully!"

exit 0