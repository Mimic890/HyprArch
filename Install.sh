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
info(){ printf "${B}%s${E}\n" "$*"; }
ok(){   printf "${G}%s${E}\n" "$*"; }
warn(){ printf "${Y}%s${E}\n" "$*"; }
err(){  printf "${R}%s${E}\n" "$*" >&2; }
############################
clear
echo -e "${B}  //////////////////////////////////
 // HyprArch installation script //
//////////////////////////////////${E}"
############################
############################


############################
#	1. Network
#############################
check_connection() {
    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        echo -e "${G}Internet connection is available${E}"
        return 0
    else
        echo -e "${R}Internet connection is not available${E}"
        return 1
    fi
}
echo -e "${B}
#################################
## Checking Network connection ##
#################################${E}"
while true; do
    if check_connection; then
        break
    else
        echo
        echo "Select an option: "
        echo -e "${G}1) Open nmtui${E}"
        echo -e "${Y}2) Check again${E}"
        echo -e "${R}3) Exit${E}"
        read -rp "$(echo -e "${Y}Your choice: ${E}")" choice
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
                echo -e "${R}Invalid choice${E}"
                ;;
        esac
    fi
done
echo -e "${G}Network check successful${E}"
sleep 0.5s
#################################
sleep 2s
#################################


############################
#	2. Activate scripts
#############################
echo -e "${B}
########################
##  Activate scripts  ##
########################${E}"
make_executable() {
    for target in "$@"; do
        if [ -e "$target" ]; then
            chmod +x "$target"
            echo -e "${G}Made executable:${E} $target"
        else
            echo -e "${R}Not found:${E} $target"
        fi
    done
}
echo -e "${B}
####################################
## Setting executable permissions ##
####################################${E}"
make_executable "$HOME/HyprArch/scripts/"* "$HOME/HyprArch/configs/hypr/scripts/"* "$HOME/HyprArch/configs/nwg-dock-hyprland/launch.sh"
echo -e "${G}Permissions set successfully${E}"
sleep 0.5s
#################################
sleep 2s
#################################


############################
#	3. Sudo password
#############################
echo -e "${B}
###################
## Sudo password ##
###################${E}"
echo -e "${B}Administrator password required for installation. Please enter your password:${E}"
sudo -v
echo -e "${G}Password accepted${E}"
sleep 0.5s
#################################
sleep 2s
#################################


#################################
#	4. Add multilib repository
##################################
echo -e "${B}
###############################
##  Add multilib repository  ##
###############################${E}"
echo -e "${B}Adding repositories...${E}"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    if echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null; then
        echo -e "${G}Multilib repository added successfully${E}"
	   sleep 0.5s
    else
        echo -e "${R}Failed to add multilib repository. Aborting installation${E}"
        exit 1
    fi
else
    echo -e "${G}Multilib repository is already enabled${E}"
fi
#################################
sleep 2s
#################################


#######################
#	5. Update system
#######################
echo -e "${B}
#######################
##  Updating system  ##
#######################${E}"
sudo pacman -Syyuu
if command -v yay >/dev/null 2>&1; then
    echo -e "${B}Found yay, updating yay...${E}"
    yay -Syyuu || echo -e "${R}Warning: yay update failed, continuing...${E}"
    yay_installed=true
else
    echo -e "${Y}yay not found${E}"
    yay_installed=false
fi
echo -e "${G}System update complete${E}"
#################################
sleep 2s
#################################


#######################
#	6. Backup
#######################
echo -e "${B}
###############################
##  Running backup script    ##
###############################${E}"
backup_script="$HOME/HyprArch/scripts/backup.sh"
if [ -x "$backup_script" ]; then
    "$backup_script"
    echo -e "${G}Backup completed successfully${E}"
else
    echo -e "${R}Backup script not found or not executable: $backup_script${E}"
    exit 1
fi
sleep 0.5s
#################################
sleep 2s
#################################


#######################################
#   7. Installing the necessary packages
########################################
echo -e "${B}
#########################################
##  Installing the necessary packages  ##
#########################################${E}"
install_packages() {
    local manager=$1
    local pkgfile=$2
    local skip_pkgs=("${!3}")
    local missing=()
    if [ ! -f "$pkgfile" ]; then
        echo -e "${R}Package list file not found: $pkgfile${E}"
        exit 1
    fi
    mapfile -t pkgs < <(grep -vE '^\s*($|#)' "$pkgfile")
    for pkg in "${pkgs[@]}"; do
        if [[ " ${skip_pkgs[*]} " == *" $pkg "* ]]; then
            echo -e "${Y}Skipping package $pkg as instructed${E}"
            continue
        fi
        if ! pacman -Qi "$pkg" >/dev/null 2>&1 && ! yay -Qi "$pkg" >/dev/null 2>&1; then
            echo -e "${B}Installing $pkg via $manager...${E}"
            if ! $manager -S --noconfirm "$pkg"; then
                missing+=("$pkg")
            fi
        else
            echo -e "${G}$pkg is already installed${E}"
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${R}The following packages failed to install via $manager:${E}"
        for p in "${missing[@]}"; do
            echo -e "${R}  - $p${E}"
        done
    else
        echo -e "${G}All $manager packages installed successfully${E}"
    fi
}
if [ "$yay_installed" = false ]; then
    skip_yay_pkg=("yay")
else
    skip_yay_pkg=()
fi
install_packages "sudo pacman" "$HOME/HyprArch/pkg/pkglist.txt" skip_yay_pkg[@]
if [ "$yay_installed" = false ]; then
    echo -e "${B}Installing yay manually because it was not found...${E}"
    cd "$HOME" && git clone https://aur.archlinux.org/yay.git
    cd "$HOME/yay"
    makepkg -si --noconfirm || echo -e "${R}Warning: yay installation failed, continuing...${E}"
    cd "$HOME"
    rm -rf "$HOME/yay"
    yay_installed=true
    echo -e "${G}yay installed successfully${E}"
    echo -e "${B}Update yay${E}"
    yay -Syyuu || echo -e "${R}Warning: yay update failed, continuing...${E}"
fi

install_packages "yay" "$HOME/HyprArch/pkg/yay.txt" skip_yay_pkg[@] || \
    echo -e "${R}Warning: Package installation via yay failed, continuing...${E}"

echo -e "${G}All package installations completed${E}"
#################################
sleep 2s
#################################


##########################
#  8. Set main monitor
###########################
echo -e "${B}
########################
##  Set main monitor  ##
########################${E}"
read -rp "Do you want to configure the main monitor now? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    MONITOR_SCRIPT="$HOME/HyprArch/scripts/monitor.sh"
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        echo -e "${R}Monitor script not found: $MONITOR_SCRIPT${E}"
        exit 1
    fi
    chmod +x "$MONITOR_SCRIPT"
    if ! "$MONITOR_SCRIPT"; then
        echo -e "${R}Error during execution $MONITOR_SCRIPT${E}"
        exit 1
    fi
    echo -e "${G}Monitor setup has been completed successfully${E}"
else
    echo -e "${Y}Skipping monitor configuration${E}"
fi
#################################
sleep 2s
#################################


######################################
#  9. Creating standard directories
#######################################
echo -e "${B}
#####################################
##  Creating standard directories  ##
#####################################${E}"
read -rp "Do you want to update XDG user directories? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    LANG=en_US.UTF-8 xdg-user-dirs-update --force
    echo -e "${G}Successfully updated XDG user directories${E}"
else
    echo -e "${Y}Skipping XDG user directories update${E}"
fi
#################################
sleep 2s
#################################


#################################
#  10. Choosing the main shell
#################################
echo -e "${B}
###############################
##  Choosing the main shell  ##
###############################${E}"
echo -e "${B}Which shell do you want to install?${E}"
echo -e "${G} 1) Keep current shell (default)${E}"
echo -e "${G} 2) Install fish shell${E}"
echo -e "${G} 3) Install zsh shell${E}"
read -p $'\e[34m Enter your choice [1/2/3]: \e[0m' shell_choice
case "$shell_choice" in
    2)
        echo -e "${B}Installing fish shell...${E}"
        bash "$HOME/HyprArch/scripts/fish.sh"
        if [ $? -ne 0 ]; then
            echo -e "${R}Fish shell installation failed. Aborting installation${E}"
            exit 1
        fi
        ;;
    3)
        echo -e "${B}Installing zsh shell...${E}"
        bash "$HOME/HyprArch/scripts/zsh.sh"
        if [ $? -ne 0 ]; then
            echo -e "${R}Zsh shell installation failed. Aborting installation${E}"
            exit 1
        fi
        ;;
    *)
        echo -e "${Y}Keeping current shell. No changes will be made${E}"
        ;;
esac
#################################
sleep 2s
#################################


#####################################
#  11. Configuring system services
#####################################
echo -e "${B}
###################################
##  Configuring system services  ##
###################################${E}"
for dm in lightdm gdm; do
    if systemctl list-units --full | grep -q "$dm"; then
        sudo systemctl disable "$dm" || {
            echo -e "${R}Failed to disable $dm${E}"
            exit 1
        }
        echo -e "${G}Disabled $dm${E}"
    fi
done
if systemctl list-units --full | grep -q "power-profiles-daemon"; then
    sudo systemctl enable power-profiles-daemon || {
        echo -e "${R}Failed to enable power-profiles-daemon${E}"
        exit 1
    }
    echo -e "${G}Enabled power-profiles-daemon${E}"
else
    echo -e "${Y}power-profiles-daemon not found, skipping${E}"
fi
sudo systemctl enable sddm || {
    echo -e "${R}Failed to enable sddm${E}"
    exit 1
}
echo -e "${G}Enabled sddm${E}"
read -rp "Do you want to use Bluetooth? [y/N]: " use_Bluetooth
if [[ "$use_Bluetooth" =~ ^[Yy]$ ]]; then
    echo -e "${B}Installing Bluetooth packages...${E}"
    sudo pacman -S --noconfirm blueman bluez bluez-utils || {
        echo -e "${R}Failed to install Bluetooth packages${E}"
        exit 1
    }
    sudo systemctl enable bluetooth || {
        echo -e "${R}Failed to enable Bluetooth service${E}"
        exit 1
    }
    echo -e "${G}Bluetooth enabled${E}"
else
    echo -e "${Y}Bluetooth setup skipped.${E}"
fi
#################################
sleep 2s
#################################


#########################################
#  12. Installing and configuring themes
##########################################
echo -e "${B}
#########################################
##  Installing and configuring themes  ##
#########################################${E}"
read -p $'\e[34m Install GTK theme? (y/n): \e[0m' install_gtk
if [[ "$install_gtk" =~ ^[Yy]$ ]]; then
    bash "$HOME/HyprArch/scripts/themes.sh"
    if [ $? -ne 0 ]; then
        echo -e "${R}Theme installation failed. Aborting installation${E}"
        exit 1
    fi
fi
#################################
sleep 2s
#################################


###################################################################
#  13. Selecting a theme for Waybar, Rofi, and Nwg-dock-hyprland
###################################################################
echo -e "${B}
#################################################################
##  Selecting a theme for waybar, rofi, and nwg-dock-hyprland  ##
#################################################################${E}"
CUSTOMS_DIR="$HOME/HyprArch/customs"
WAYBAR_DIR="$HOME/.config/waybar"
ROFI_DIR="$HOME/.config/rofi"
DOCK_DIR="$HOME/.config/nwg-dock-hyprland"

THEMES=("blue_arch" "black_arch" "white_arch" "amoled_arch" "purple_arch" "orange_arch")

echo -e "${B}Available themes:${E}"
echo "0) Skip theme setup"
for i in "${!THEMES[@]}"; do
    echo "$((i+1))) ${THEMES[i]}"
done

read -p "Enter the number of your choice: " choice

if [[ "$choice" == "0" ]]; then
    echo -e "${Y}Skipping theme setup...${E}"
fi

THEME_NAME="${THEMES[$((choice-1))]}"

if [[ -z "$THEME_NAME" ]]; then
    echo -e "${R}Invalid choice. Exiting.${E}"
    exit 1
fi

echo -e "${G}Selected theme: $THEME_NAME${E}"

echo -e "${B}Applying theme for Waybar...${E}"
mkdir -p "$WAYBAR_DIR"
rm -f "$WAYBAR_DIR"/*.css
cp "$CUSTOMS_DIR/waybar/${THEME_NAME}.css" "$WAYBAR_DIR/style.css"

echo -e "${B}Applying theme for Rofi...${E}"
mkdir -p "$ROFI_DIR"
rm -f "$ROFI_DIR"/*.rasi
cp "$CUSTOMS_DIR/rofi/${THEME_NAME}.rasi" "$ROFI_DIR/config.rasi"

echo -e "${B}Applying theme for nwg-dock-hyprland...${E}"
mkdir -p "$DOCK_DIR"
rm -f "$DOCK_DIR"/*.css
cp "$CUSTOMS_DIR/nwg-dock-hyprland/${THEME_NAME}.css" "$DOCK_DIR/style.css"

echo -e "${G}Theme applied successfully for all components!${E}"
#################################
sleep 2s
#################################


################################
#  14. Copying configurations
################################
echo -e "${B}
##############################
##  Copying configurations  ##
##############################${E}"

SRC_DIR="$HOME/HyprArch/configs"
DEST_DIR="$HOME/.config"
BACKUP_BASE="$HOME/.config_backup/hyprarch_$(date +%Y%m%d_%H%M%S)"

echo -e "${B}>>> Starting configuration sync...${E}"
if [ ! -d "$SRC_DIR" ]; then
    echo -e "${R}Error:${E} Source directory $SRC_DIR does not exist."
    exit 1
fi

if command -v rsync >/dev/null 2>&1; then
    _use_rsync=1
else
    _use_rsync=0
    echo -e "${Y}Note:${E} rsync not found — using safe cp/mv fallback."
fi

mkdir -p "$BACKUP_BASE" "$DEST_DIR"
shopt -s dotglob nullglob

hypr_items=()
for item in "$SRC_DIR"/*; do
    name="$(basename "$item")"
    lname="${name,,}"
    if [[ "$lname" == "hypr" || "$lname" == "hyprland" ]]; then
        hypr_items+=("$item")
        continue
    fi

    dest_path="$DEST_DIR/$name"
    echo -e "${B}>>> Processing:${E} $name"

    if [ -e "$dest_path" ]; then
        echo -e "${Y}Backing up:${E} $dest_path → $BACKUP_BASE/$name"
        mkdir -p "$BACKUP_BASE/$name"
    fi

    if [ "$_use_rsync" -eq 1 ]; then
        mkdir -p "$dest_path"
        rsync -a --delete --backup --backup-dir="$BACKUP_BASE/$name" --no-owner --no-group "$item"/ "$dest_path"/ \
            || { echo -e "${R}rsync failed for $name${E}"; exit 1; }
    else
        tmp_dest="${DEST_DIR}/${name}.tmp_$$"
        rm -rf "$tmp_dest"
        mkdir -p "$(dirname "$tmp_dest")"
        cp -a "$item" "$tmp_dest" || { echo -e "${R}cp failed for $name${E}"; exit 1; }
        if [ -e "$dest_path" ]; then
            mv "$dest_path" "$BACKUP_BASE/$name" || { echo -e "${R}backup mv failed for $name${E}"; exit 1; }
        fi
        mv "$tmp_dest" "$dest_path" || { echo -e "${R}mv failed for $name${E}"; exit 1; }
    fi

    sync
    sleep 0.4
done

if [ "${#hypr_items[@]}" -gt 0 ]; then
    echo -e "${Y}Note:${E} Handling Hypr configs at the end to avoid display glitches."
    sleep 0.8

    if command -v hyprland >/dev/null 2>&1; then
        echo -e "${Y}Warning:${E} Hyprland appears to be running. Applying configs without auto-reload to avoid resolution issues."
        _reload_ok=0
    else
        _reload_ok=1
    fi

    for item in "${hypr_items[@]}"; do
        name="$(basename "$item")"
        dest_path="$DEST_DIR/$name"
        echo -e "${B}>>> Processing (hypr):${E} $name"

        if [ -e "$dest_path" ]; then
            echo -e "${Y}Backing up:${E} $dest_path → $BACKUP_BASE/$name"
            mkdir -p "$BACKUP_BASE/$name"
        fi

        if [ "$_use_rsync" -eq 1 ]; then
            mkdir -p "$dest_path"
            rsync -a --delete --backup --backup-dir="$BACKUP_BASE/$name" --no-owner --no-group "$item"/ "$dest_path"/ \
                || { echo -e "${R}rsync failed for $name${E}"; exit 1; }
        else
            tmp_dest="${DEST_DIR}/${name}.tmp_$$"
            rm -rf "$tmp_dest"
            mkdir -p "$(dirname "$tmp_dest")"
            cp -a "$item" "$tmp_dest" || { echo -e "${R}cp failed for $name${E}"; exit 1; }
            if [ -e "$dest_path" ]; then
                mv "$dest_path" "$BACKUP_BASE/$name" || { echo -e "${R}backup mv failed for $name${E}"; exit 1; }
            fi
            mv "$tmp_dest" "$dest_path" || { echo -e "${R}mv failed for $name${E}"; exit 1; }
        fi

        sync
        sleep 1.0
    done

    if [ "$_reload_ok" -eq 1 ] && command -v hyprctl >/dev/null 2>&1; then
        echo -e "${B}>>> Applying Hypr config:${E} hyprctl reload"
        if ! hyprctl reload; then
            echo -e "${R}hyprctl reload failed.${E} You may need to relogin or reboot to apply display changes."
        fi
        sleep 1
    else
        echo -e "${Y}Skipping auto-reload for Hyprland.${E} Changes will apply after relogin or reboot."
    fi
fi

echo -e "${G}All configs have been synced successfully.${E}"
echo -e "${C}Backups (if any) are in:${E} $BACKUP_BASE"
#################################
sleep 2s
#################################


####################################
#  15. Configuring SDDM and GRUB
####################################
echo -e "${B}
#################################
##  Configuring SDDM and GRUB  ##
#################################${E}"
read -rp "Do you want to install HyprArch themes for SDDM and GRUB? [y/N] " ans

if [[ "$ans" =~ ^[Yy]$ ]]; then
    if bash "$HOME/HyprArch/scripts/sddm.sh"; then
        echo -e "${G}SDDM configured successfully${E}"
    else
        echo -e "${R}SDDM configuration failed. Aborting.${E}"
        exit 1
    fi

    if bash "$HOME/HyprArch/scripts/grub.sh"; then
        echo -e "${G}GRUB configured successfully${E}"
    else
        echo -e "${R}GRUB configuration failed. Aborting.${E}"
        exit 1
    fi

    echo -e "${G}SDDM & GRUB configured successfully${E}"
else
    echo -e "${Y}Skipping SDDM & GRUB theme installation${E}"
fi
#################################
sleep 2s
#################################


###############################################
#  16. Detect GPU and install proper drivers
###############################################
echo -e "${B}
############################################
##  Detect GPU and install proper drivers ##
############################################${E}"
echo -e "${B}Detecting GPU and preparing drivers for Hyprland...${E}"

multilib_enabled() {
  grep -q "^\[multilib\]" /etc/pacman.conf
}

install_pkg() {
  local pkg="$1"
  echo -ne "${Y}Installing ${pkg}...${E} "
  if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
    echo -e "${G}[OK]${E}"
  else
    echo -e "${R}[FAILED]${E}"
    FAILED_PKGS+=("$pkg")
  fi
}

FAILED_PKGS=()

GPU_INFO="$(lspci -nnk | grep -A3 -E 'VGA|3D|Display' || true)"
echo -e "${B}Detected adapters:${E}"
echo "$GPU_INFO" | sed 's/^/  /'

HAS_NVIDIA=false
HAS_AMD=false
HAS_INTEL=false
IS_INTEL_ARC=false

echo "$GPU_INFO" | grep -qi 'NVIDIA'       && HAS_NVIDIA=true
echo "$GPU_INFO" | grep -qi 'AMD/ATI'      && HAS_AMD=true
echo "$GPU_INFO" | grep -qi 'Intel'        && HAS_INTEL=true
if $HAS_INTEL && echo "$GPU_INFO" | grep -qiE 'Arc|DG2|Alchemist'; then
  IS_INTEL_ARC=true
fi

if $HAS_NVIDIA; then
  echo -e "${B}NVIDIA GPU detected. Delegating to nvidia.sh...${E}"
  if [ -x "$HOME/HyprArch/scripts/nvidia.sh" ]; then
    if ! "$HOME/HyprArch/scripts/nvidia.sh"; then
      echo -e "${R}nvidia.sh failed. Aborting.${E}"
      exit 1
    fi
  else
    echo -e "${Y}nvidia.sh is not executable; running with bash.${E}"
    if ! bash "$HOME/HyprArch/scripts/nvidia.sh"; then
      echo -e "${R}nvidia.sh failed. Aborting.${E}"
      exit 1
    fi
  fi

elif $HAS_AMD; then
  echo -e "${B}AMD GPU detected. Installing Mesa/Radeon stack...${E}"
  AMD_PKGS=(mesa vulkan-radeon libva-mesa-driver vulkan-mesa-layers)
  if multilib_enabled; then
    AMD_PKGS+=(lib32-vulkan-radeon lib32-mesa)
  fi
  for p in "${AMD_PKGS[@]}"; do install_pkg "$p"; done

elif $HAS_INTEL; then
  if $IS_INTEL_ARC; then
    echo -e "${B}Intel Arc GPU detected. Installing Intel Vulkan/Media stack...${E}"
  else
    echo -e "${B}Intel iGPU detected. Installing Intel Vulkan/Media stack...${E}"
  fi
  INTEL_PKGS=(mesa vulkan-intel intel-media-driver vulkan-mesa-layers)
  if multilib_enabled; then
    INTEL_PKGS+=(lib32-vulkan-intel lib32-mesa)
  fi
  for p in "${INTEL_PKGS[@]}"; do install_pkg "$p"; done
else
  echo -e "${Y}No supported GPU vendor detected (NVIDIA/AMD/Intel). Skipping GPU driver setup.${E}"
fi
if [ "${#FAILED_PKGS[@]}" -gt 0 ]; then
  echo -e "${R}Some packages failed to install:${E} ${FAILED_PKGS[*]}"
  echo -e "${Y}You may re-run this step after fixing mirrors/network or try again later.${E}"
  exit 1
fi

echo -e "${G}GPU detection and driver setup completed successfully.${E}"
#################################
sleep 2s
#################################


###############################
#  17. Replace /etc/os-release
###############################
bash "$HOME/HyprArch/scripts/os.sh"
####################################
####################################


###############################
#  18. Wallpapers installation
###############################
bash "$HOME/HyprArch/scripts/wallpapers.sh"
#################################
sleep 2s
#################################


#################################################
#  19. Selecting a text editors in the terminal
#################################################
info "###############################################"
info "##  Selecting a text editor in the terminal  ##"
info "###############################################"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$(id -un)"
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"

CUSTOM_NVIM_FILE="$TARGET_HOME/HyprArch/customs/nvim/init.lua"

NVIM_CONF_DIR="$TARGET_HOME/.config/nvim"
NVIM_CONF_INIT="$NVIM_CONF_DIR/init.lua"

if ! command -v pacman &>/dev/null; then
  err "pacman not found. This script is intended for Arch Linux."
  exit 1
fi

USE_WHIPTAIL=false
if command -v whiptail &>/dev/null; then
  USE_WHIPTAIL=true
fi

CHOICES=()
CHOICES+=("nano"   "Nano (simple)" off)
CHOICES+=("vim"    "Vim (classic)" off)
CHOICES+=("nvimc"  "Neovim (my custom init.lua)" off)
CHOICES+=("astro"  "Neovim (AstroNvim upstream)" off)

selected_items=()

if $USE_WHIPTAIL; then
  ARGS=()
  for ((i=0;i<${#CHOICES[@]}; i+=3)); do
    ARGS+=("${CHOICES[i]}" "${CHOICES[i+1]}" "OFF")
  done

  SELECTION=$(whiptail --title "Select editors to install" --checklist \
    "Choose editors (SPACE to toggle):" 20 80 10 \
    "${ARGS[@]}" 3>&1 1>&2 2>&3) || {
      warn "Selection cancelled by user. Exiting."
      exit 0
  }

  eval "selected_items=($SELECTION)"
else
  info "No whiptail detected — fallback to textual selection."
  echo
  echo "Available editors:"
  echo " 1) nano        - simple editor"
  echo " 2) vim         - classic vim"
  echo " 3) neovim-c    - neovim with your custom init.lua"
  echo " 4) astrovim    - AstroNvim (upstream)"
  echo
  read -rp $'\e[34mEnter numbers separated by spaces (e.g. 1 3): \e[0m' ans
  for n in $ans; do
    case $n in
      1) selected_items+=("nano") ;;
      2) selected_items+=("vim") ;;
      3) selected_items+=("nvimc") ;;
      4) selected_items+=("astro") ;;
      *) warn "Unknown option: $n" ;;
    esac
  done
fi

if [ ${#selected_items[@]} -eq 0 ]; then
  warn "No editors selected. Exiting."
  exit 0
fi

pac_install() {
  local pkgs=("$@")
  info "Installing: ${pkgs[*]}"
  if sudo pacman -S --noconfirm --needed "${pkgs[@]}"; then
    ok "Installed: ${pkgs[*]}"
  else
    warn "Initial pacman install failed — updating DB and retrying..."
    sudo pacman -Sy --noconfirm
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
  fi
}

NEOVIM_BASE_PKGS=(neovim python-pynvim nodejs npm git)

need_neovim=false
for t in "${selected_items[@]}"; do
  case "$t" in
    "nvimc"|"astro") need_neovim=true ;;
  esac
done

for rawtag in "${selected_items[@]}"; do
  tag="${rawtag%\"}"
  tag="${tag#\"}"
  case "$tag" in
    nano)
      pac_install nano
      ;;
    vim)
      pac_install vim
      ;;
    nvimc)
      pac_install "${NEOVIM_BASE_PKGS[@]}"
      ;;
    astro)
      pac_install "${NEOVIM_BASE_PKGS[@]}"
      ;;
  esac
done

if printf '%s\n' "${selected_items[@]}" | grep -qx "nvimc"; then
  info "Setting up Neovim custom init.lua..."
  if [ ! -f "$CUSTOM_NVIM_FILE" ]; then
    warn "Custom init.lua not found at: $CUSTOM_NVIM_FILE. Skipping custom install."
  else
    mkdir -p "$NVIM_CONF_DIR"
    if [ "$TARGET_USER" != "$(id -un)" ]; then
      sudo -u "$TARGET_USER" cp -f "$CUSTOM_NVIM_FILE" "$NVIM_CONF_INIT"
      sudo chown "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_INIT"
    else
      cp -f "$CUSTOM_NVIM_FILE" "$NVIM_CONF_INIT"
      chown "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_INIT"
    fi
    ok "Custom init.lua installed to $NVIM_CONF_INIT (overwritten if existed)."
    warn "You may need to open Neovim once to install plugins (e.g. run :PackerSync or :Lazy sync)."
  fi
fi

if printf '%s\n' "${selected_items[@]}" | grep -qx "astro"; then
  info "Setting up AstroNvim..."
  ASTRO_REPO="https://github.com/AstroNvim/template"
  if [ -d "$NVIM_CONF_DIR" ] && [ ! -z "$(ls -A "$NVIM_CONF_DIR")" ]; then
    warn "$NVIM_CONF_DIR already exists — skipping AstroNvim clone to avoid overwrite."
    warn "If you want AstroNvim, remove or rename the existing $NVIM_CONF_DIR and re-run this step."
  else
    if [ "$TARGET_USER" != "$(id -un)" ]; then
      sudo -u "$TARGET_USER" git clone --depth=1 "$ASTRO_REPO" "$NVIM_CONF_DIR"
      sudo chown -R "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_DIR"
    else
      git clone --depth=1 "$ASTRO_REPO" "$NVIM_CONF_DIR"
      rm -rf "$HOME/.config/nvim/.git"
      chown -R "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_DIR"
    fi
    ok "AstroNvim cloned into $NVIM_CONF_DIR."
    warn "To install AstroNvim plugins, run (as user): nvim --headless +Lazy sync +qa or open Neovim once."
  fi
fi

echo
ok "Done. Selected editors installed and configured (where configs were available)."
#################################
sleep 2s
#################################


#####################################
#  20. Installing additional programs
#####################################
info "######################################"
info "##  Installing additional programs  ##"
info "######################################"
bash "$HOME/HyprArch/scripts/programms.sh"
#################################
sleep 2s
#################################

######################################################
#  21. Adding the BlackArch repository (optional)
######################################################
info "##################################################"
info "##  Adding the BlackArch repository (optional)  ##"
info "##################################################"
bash "$HOME/HyprArch/scripts/blackarch.sh"
#################################
sleep 2s
#################################



ok "  ////////////////////////////////////////////"
ok " //  Installation completed successfully!  //"
ok "////////////////////////////////////////////"

echo
read -rp "$(printf "${Y}Would you like to reboot now? (Y/n): ${E}")" reboot_choice
echo

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    info "Rebooting the system..."
    sleep 2
    sudo reboot
else
    info "Installation completed successfully!"
    warn "Please reboot your system to apply all changes."

    echo
    echo -e "${B}====================[ HyprArch Installed ]====================${E}"
    echo -e "   ${G}✔${E} Your system is ready."
    echo -e "   ${Y}➜${E} Reboot is recommended before first login."
    echo
    echo -e "   ${C}Official website:${E} ${B}https://hyprarch.ru${E}"
    echo -e "   ${C}Community chat:${E}   ${B}https://t.me/hyprarch${E}"
    echo
    echo -e "${B}=============================================================${E}"
    echo
    exit 0
fi
