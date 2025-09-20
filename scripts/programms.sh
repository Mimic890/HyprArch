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
  "OBS|OBS Studio|obs-studio|yay|screen recording and streaming (AUR)"
  "DISCORD|Discord|discord|pacman|voice and text chat"
  "PRISM LAUNCHER|Prism Launcher|prismlauncher|pacman|Minecraft launcher"
  "VERACRYPT|VeraCrypt|veracrypt|pacman|disk encryption"
  "SIGNAL|Signal|signal-desktop|pacman|security messenger"
  "FOLIATE|Foliate|foliate|pacman|books and pdf reader"
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
  "THRONE|Throne|throne-bin|yay|sing-box client (AUR)"
  "MOTRIX|Motrix|motrix-bin|yay|download manager (AUR)"
  "AYUGRAM|AyuGram|ayugram-bin|yay|telegram client (AUR)"
  "ANYTYPE|Anytype|anytype-bin|yay|note-taking app (AUR)"
)

if ! command -v whiptail &>/dev/null; then
  info "Installing whiptail..."
  sudo pacman -Sy --noconfirm whiptail
fi

WHIP_ARGS=()
for item in "${ITEMS[@]}"; do
  IFS='|' read -r TAG LABEL PKG MGR DESC <<<"$item"
  WHIP_ARGS+=("$TAG" "$LABEL — $DESC" OFF)
done

CHOICES=$(whiptail --title "Choose applications" --checklist \
"Select programs to install (SPACE — select, TAB — move, Enter — OK):" 25 80 15 \
"${WHIP_ARGS[@]}" 3>&1 1>&2 2>&3) || {
  warn "Installation cancelled by user."
  exit 0
}

if [ -z "$CHOICES" ]; then
  warn "No programs selected. Exiting."
fi

eval "set -- $CHOICES"
SELECTED=("$@")

declare -A PKG_MAP MGR_MAP LABEL_MAP
for item in "${ITEMS[@]}"; do
  IFS='|' read -r TAG LABEL PKG MGR DESC <<<"$item"
  PKG_MAP["$TAG"]="$PKG"
  MGR_MAP["$TAG"]="$MGR"
  LABEL_MAP["$TAG"]="$LABEL"
done

pacman_pkgs=()
yay_pkgs=()

info "Sorting selected packages by manager..."
for tag_raw in "${SELECTED[@]}"; do
  tag=${tag_raw//\"/}
  pkg=${PKG_MAP[$tag]}
  mgr=${MGR_MAP[$tag]}

  if [ "$mgr" = "pacman" ]; then
    pacman_pkgs+=($pkg)
  elif [ "$mgr" = "yay" ]; then
    yay_pkgs+=($pkg)
  fi
done

install_yay() {
  info "Installing prerequisites for AUR builds (git, base-devel)..."
  sudo pacman -Sy --needed --noconfirm git base-devel
  info "Cloning and building yay..."
  local tmpd
  tmpd=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpd/yay"
  (cd "$tmpd/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpd"
  ok "yay installed."
}

if [ ${#yay_pkgs[@]} -gt 0 ] && ! command -v yay &>/dev/null; then
  read -rp "$(warn "Some of your selections require 'yay' (AUR). Install yay now? (y/N): ")" resp
  if [[ "$resp" =~ ^[Yy]$ ]]; then
    install_yay
  else
    err "Cannot install AUR packages without yay. Aborting."
    yay_pkgs=()
  fi
fi

if [ ${#pacman_pkgs[@]} -gt 0 ]; then
  info "Installing packages via pacman: ${pacman_pkgs[*]}"
  if sudo pacman -S --noconfirm --needed "${pacman_pkgs[@]}"; then
    ok "Pacman packages installed successfully."
  else
    err "An error occurred during pacman package installation. Check the output above."
  fi
fi

if [ ${#yay_pkgs[@]} -gt 0 ]; then
  if command -v yay &>/dev/null; then
    info "Installing AUR packages via yay: ${yay_pkgs[*]}"
    if yay -S --noconfirm --needed "${yay_pkgs[@]}"; then
      ok "AUR packages installed successfully."
    else
      err "An error occurred during AUR package installation. Check the output above."
    fi
  else
    err "yay is not installed. Skipping AUR packages: ${yay_pkgs[*]}"
  fi
fi

ok "Installation process finished."

if pacman -Q visual-studio-code-bin &>/dev/null; then
  if [ -f "$HOME/HyprArch/scripts/vs-code.sh" ]; then
    if bash "$HOME/HyprArch/scripts/vs-code.sh"; then
      ok "HyprVSCode custom settings applied successfully!"
    else
      err "Error applying HyprVSCode custom settings!"
    fi
  else
    warn "VS-Code custom script not found, skipping."
  fi
else
  info "VS-Code is not installed, skipping custom settings."
fi

exit 0
