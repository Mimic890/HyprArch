#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Colors
B="\e[34m"; G="\e[32m"; Y="\e[33m"; R="\e[31m"; E="\e[0m"
info(){  echo -e "${B}$*${E}"; }
ok(){    echo -e "${G}$*${E}"; }
warn(){  echo -e "${Y}$*${E}"; }
err(){   echo -e "${R}$*${E}" >&2; }

usage(){
  cat <<EOF
Usage: $0 [-y|--yes]
Sequential installer for editors (nano, vim, neovim) and neovim config choice.
Run as root (sudo).
Options:
  -y, --yes   non-interactive: answer yes to all confirmations
EOF
}

AUTO_YES=false
while [[ ${1:-} != "" ]]; do
  case "$1" in
    -y|--yes) AUTO_YES=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

# Determine target user (when called via sudo)
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

confirm(){
  local prompt="${1:-Proceed?}"
  if $AUTO_YES; then
    return 0
  fi
  if $USE_WHIPTAIL; then
    if whiptail --title "Confirm" --yesno "$prompt" 10 60; then
      return 0
    else
      return 1
    fi
  else
    read -rp "$(echo -e "${Y}${prompt} (y, N): ${E}")" _ans
    [[ "$_ans" =~ ^[Yy]$ ]]
  fi
}

pac_install(){
  local pkgs=("$@")
  info "Installing: ${pkgs[*]}"
  if sudo pacman -S --noconfirm --needed "${pkgs[@]}"; then
    ok "Installed: ${pkgs[*]}"
    return 0
  else
    warn "Initial pacman install failed — updating DB and retrying..."
    sudo pacman -Sy --noconfirm
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
  fi
}

# safe clear function: deletes only inside NVIM_CONF_DIR
clear_nvim_dir(){
  # If dir doesn't exist, nothing to clear
  if [ ! -d "$NVIM_CONF_DIR" ]; then
    return 0
  fi

  # Ask for confirmation (unless AUTO_YES)
  if ! confirm "This will REMOVE ALL CONTENTS of $NVIM_CONF_DIR. Continue?" N; then
    warn "User cancelled removal of $NVIM_CONF_DIR."
    return 1  # caller should interpret as cancellation
  fi

  info "Removing contents of $NVIM_CONF_DIR..."
  # Use find -mindepth 1 -delete to remove everything inside safely
  # run as root to ensure deletion; then recreate dir and set ownership to target user
  find "$NVIM_CONF_DIR" -mindepth 1 -exec rm -rf {} + || true

  # ensure directory exists and owned by target user
  mkdir -p "$NVIM_CONF_DIR"
  chown -R "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_DIR"
  ok "Cleared $NVIM_CONF_DIR"
  return 0
}

info "Target user: $TARGET_USER ($TARGET_HOME)"
echo

install_nano=false
install_vim=false
install_neovim=false

if confirm "Install nano?" N; then
  install_nano=true
fi

if confirm "Install vim?" N; then
  install_vim=true
fi

if confirm "Install neovim (base packages)?" N; then
  install_neovim=true
fi

if ! $install_nano && ! $install_vim && ! $install_neovim; then
  warn "No editors selected. Exiting."
  exit 0
fi

if $install_nano; then
  pac_install nano || warn "Failed to install nano"
fi

if $install_vim; then
  pac_install vim || warn "Failed to install vim"
fi

NEOVIM_BASE_PKGS=(neovim python-pynvim nodejs npm git)

if $install_neovim; then
  pac_install "${NEOVIM_BASE_PKGS[@]}" || warn "Failed to install neovim base packages"

  NVIM_CHOICE=""
  if $USE_WHIPTAIL; then
    NVIM_CHOICE=$(whiptail --title "Neovim config" --menu "Choose Neovim setup (select one):" 15 70 4 \
      "clean" "Keep Neovim config directory empty / do nothing" \
      "custom" "Install your custom init.lua (from $CUSTOM_NVIM_FILE)" \
      "astro" "Install AstroNvim (clone upstream template)" \
      3>&1 1>&2 2>&3) || NVIM_CHOICE=""
  else
    echo
    echo "Neovim setup options:"
    echo " 1) clean  - keep ~/.config/nvim empty (no config)"
    echo " 2) custom - install your custom init.lua (from $CUSTOM_NVIM_FILE)"
    echo " 3) astro  - install AstroNvim (upstream template)"
    echo
    read -rp $'\e[34mChoose option number (1-3, default 1): \e[0m' nv_choice
    case "${nv_choice:-1}" in
      1) NVIM_CHOICE="clean" ;;
      2) NVIM_CHOICE="custom" ;;
      3) NVIM_CHOICE="astro" ;;
      *) NVIM_CHOICE="clean" ;;
    esac
  fi

  NVIM_CHOICE="${NVIM_CHOICE:-clean}"
  info "Selected Neovim option: $NVIM_CHOICE"

  # Before applying any option: clear existing config dir
  if ! clear_nvim_dir; then
    warn "Skipping Neovim configuration step due to user cancellation."
    # skip the rest of neovim config actions
    NVIM_CHOICE="skip"
  fi

  case "$NVIM_CHOICE" in
    skip)
      info "Neovim configuration skipped."
      ;;
    clean)
      info "Left $NVIM_CONF_DIR empty (clean)."
      # ensure ownership already set by clear_nvim_dir
      ;;
    custom)
      if [ ! -f "$CUSTOM_NVIM_FILE" ]; then
        warn "Custom init.lua not found at: $CUSTOM_NVIM_FILE. Skipping custom install."
      else
        # ensure dir exists
        mkdir -p "$NVIM_CONF_DIR"
        # copy file as target user
        if [ "$TARGET_USER" != "$(id -un)" ]; then
          sudo -u "$TARGET_USER" cp -f "$CUSTOM_NVIM_FILE" "$NVIM_CONF_INIT"
          sudo chown "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_INIT"
        else
          cp -f "$CUSTOM_NVIM_FILE" "$NVIM_CONF_INIT"
          chown "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_INIT"
        fi
        ok "Custom init.lua installed to $NVIM_CONF_INIT (overwritten if existed)."
        warn "Open Neovim once to install plugins (e.g. run :PackerSync or :Lazy sync)."
      fi
      ;;
    astro)
      ASTRO_REPO="https://github.com/AstroNvim/template"
      # At this point NVIM_CONF_DIR is empty (or was created). Clone template
      if [ "$TARGET_USER" != "$(id -un)" ]; then
        sudo -u "$TARGET_USER" git clone --depth=1 "$ASTRO_REPO" "$NVIM_CONF_DIR"
        sudo chown -R "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_DIR"
        sudo -u "$TARGET_USER" rm -rf "$NVIM_CONF_DIR/.git" || true
      else
        git clone --depth=1 "$ASTRO_REPO" "$NVIM_CONF_DIR"
        rm -rf "$NVIM_CONF_DIR/.git" || true
        chown -R "$TARGET_USER":"$TARGET_USER" "$NVIM_CONF_DIR"
      fi
      ok "AstroNvim template cloned into $NVIM_CONF_DIR."
      warn "To install AstroNvim plugins, run (as user): nvim --headless +Lazy sync +qa or open Neovim once."
      ;;
    *)
      warn "Unknown Neovim choice: $NVIM_CHOICE"
      ;;
  esac
fi

echo
ok "Done. Selected editors installed and Neovim configuration processed."
