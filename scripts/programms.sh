#!/usr/bin/env bash
set -euo pipefail

# Colors
B="\e[34m"
G="\e[32m"
Y="\e[33m"
R="\e[31m"
E="\e[0m"

info(){  echo -e "${B}$*${E}"; }
ok(){    echo -e "${G}$*${E}"; }
warn(){  echo -e "${Y}$*${E}"; }
err(){   echo -e "${R}$*${E}" >&2; }

# ======== Program list (add new entries here) ========
# Format: TAG|Label|package_name|manager|description
# manager: pacman or yay
ITEMS=(
  "TELEGRAM|Telegram|telegram-desktop|pacman|messenger"
  "STEAM|Steam|steam|pacman|game platform"
  "OBS|OBS Studio|obs-studio|yay|screen recording and streaming"
  "DISCORD|Discord|discord|pacman|voice and text chat"
  "VERACRYPT|VeraCrypt|veracrypt|pacman|disk encryption"
  "FOLIATE|Foliate|foliate|pacman|books and pdf reader"
  "MOTRIX|Motrix|motrix-bin|yay|download manager"
  "GIMP|GIMP|gimp|pacman|image editor"
  "KRITA|Krita|krita|pacman|image editor"
  "INKSCAPE|Inkscape|inkscape|pacman|vector graphics editor"
  "KDENLIVE|Kdenlive|kdenlive|pacman|video editor"
  "KEEPASSXC|KeePassXC|keepassxc|pacman|password manager"
  "LIBREOFFICE|LibreOffice|libreoffice-fresh|pacman|office suite"
  "VSCODE|VS Code|visual-studio-code-bin|yay|editor (AUR)"
  "SPOTIFY|Spotify|spotify|yay|music (AUR)"
  "OBSIDIAN|Obsidian|obsidian|yay|notes (AUR)"
  "YANDEXMUSIC|Yandex Music|yandex-music|yay|music (AUR)"
  "THRONE|Throne|throne-bin|yay|sing-box client"
)

# ======================================================

# Ensure whiptail exists
if ! command -v whiptail &>/dev/null; then
  info "Installing whiptail..."
  sudo pacman -Sy --noconfirm whiptail
fi

# Build whiptail checklist arguments
WHIP_ARGS=()
for item in "${ITEMS[@]}"; do
  IFS='|' read -r TAG LABEL PKG MGR DESC <<<"$item"
  # show label and short description as the item text
  WHIP_ARGS+=("$TAG" "$LABEL — $DESC" OFF)
done

CHOICES=$(whiptail --title "Choose applications" --checklist \
"Select programs to install (SPACE — select, TAB — move, Enter — OK):" 25 80 15 \
"${WHIP_ARGS[@]}" 3>&1 1>&2 2>&3) || {
  warn "Installation cancelled by user."
  exit 1
}

# Parse choices (whiptail returns a quoted list, eval to get tokens)
eval "set -- $CHOICES"
SELECTED=("$@")

if [ ${#SELECTED[@]} -eq 0 ]; then
  warn "No programs selected. Exiting."
  exit 0
fi

# Create associative maps for quick lookup
declare -A PKG_MAP MGR_MAP LABEL_MAP
for item in "${ITEMS[@]}"; do
  IFS='|' read -r TAG LABEL PKG MGR DESC <<<"$item"
  PKG_MAP["$TAG"]="$PKG"
  MGR_MAP["$TAG"]="$MGR"
  LABEL_MAP["$TAG"]="$LABEL"
done

# Check if we need yay (any selected package uses yay)
need_yay=false
for tag in "${SELECTED[@]}"; do
  tag=${tag//\"/}  # remove possible quotes
  mgr=${MGR_MAP[$tag]}
  if [ "$mgr" = "yay" ]; then
    need_yay=true
    break
  fi
done

# Install yay if needed
install_yay() {
  info "Installing prerequisites for AUR builds (git, base-devel)..."
  sudo pacman -Sy --needed --noconfirm git base-devel
  info "Cloning and building yay..."
  tmpd=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpd/yay"
  (cd "$tmpd/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpd"
  ok "yay installed."
}

if $need_yay && ! command -v yay &>/dev/null; then
  read -rp "$(echo -e "${Y}Some of your selections require 'yay' (AUR). Install yay now? (y/N): ${E}")" resp
  if [[ "$resp" =~ ^[Yy]$ ]]; then
    install_yay
  else
    err "Cannot install AUR packages without yay. Please install yay or unselect AUR packages."
    # exit or continue only with pacman packages — here we exit
    exit 1
  fi
fi

# Install selected packages
failed=()
succeeded=()
for rawtag in "${SELECTED[@]}"; do
  tag=${rawtag//\"/}
  pkg=${PKG_MAP[$tag]}
  mgr=${MGR_MAP[$tag]}
  label=${LABEL_MAP[$tag]}

  info "Installing ${label} (${pkg}) via ${mgr}..."
  if [ "$mgr" = "pacman" ]; then
    if sudo pacman -S --noconfirm "$pkg"; then
      ok "${label} installed."
      succeeded+=("$label")
    else
      err "${label} installation failed."
      failed+=("$label")
    fi
  elif [ "$mgr" = "yay" ]; then
    if ! command -v yay &>/dev/null; then
      err "yay is not installed; cannot install ${label}."
      failed+=("$label")
      continue
    fi
    if yay -S --noconfirm "$pkg"; then
      ok "${label} installed."
      succeeded+=("$label")
    else
      err "${label} installation failed."
      failed+=("$label")
    fi
  else
    warn "Unknown manager '${mgr}' for ${label}, skipping."
    failed+=("$label")
  fi
done

# Summary
echo
ok "Installation finished."
if [ ${#succeeded[@]} -ne 0 ]; then
  echo -e "${G}Installed:${E}"
  for p in "${succeeded[@]}"; do echo -e "  - $p"; done
fi

if [ ${#failed[@]} -ne 0 ]; then
  echo -e "${R}Failed to install:${E}"
  for p in "${failed[@]}"; do echo -e "  - $p"; done
  echo
  warn "You can re-run this script to try again for failed packages."
else
  ok "All selected packages installed successfully."
fi
