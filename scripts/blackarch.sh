#!/usr/bin/env bash
set -euo pipefail
# Colors
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

if ! command -v pacman &>/dev/null; then
  err "This script is intended for Arch Linux (pacman not found)."
  exit 1
fi

read -rp "$(echo -e "${B}Do you want to add the BlackArch repository? (Y/n): ${E}")" add_blackarch
if [[ -z "$add_blackarch" || "$add_blackarch" =~ ^[Yy]$ ]]; then
  if grep -qE '^\[blackarch\]' /etc/pacman.conf; then
    ok "BlackArch repo already present in /etc/pacman.conf."
  else
    if ! command -v curl &>/dev/null; then
      warn "curl not found. Installing curl..."
      sudo pacman -Sy --noconfirm curl
    fi
    info "Downloading BlackArch strap script to /tmp/strap.sh..."
    tmpstrap="/tmp/strap.sh"
    if curl -fsSL -o "$tmpstrap" https://blackarch.org/strap.sh; then
      chmod +x "$tmpstrap"
      info "Running strap script (this requires sudo)..."
      if sudo bash "$tmpstrap"; then
        ok "BlackArch repository added successfully."
      else
        err "strap.sh failed. Aborting."
        rm -f "$tmpstrap"
        exit 1
      fi
      rm -f "$tmpstrap"
      info "Updating pacman package databases..."
      sudo pacman -Sy
    else
      err "Failed to download strap.sh from blackarch.org."
      exit 1
    fi
  fi
else
  warn "Skipping addition of BlackArch repository."
fi

if ! command -v whiptail &>/dev/null; then
  warn "whiptail not found. Installing whiptail..."
  sudo pacman -Sy --noconfirm whiptail
fi

info "Gathering BlackArch package groups..."
sudo pacman -Sy >/dev/null
mapfile -t raw_groups < <(pacman -Sg 2>/dev/null | awk '{print $1}' | grep '^blackarch-' | sort -u)

if [ ${#raw_groups[@]} -eq 0 ]; then
  err "No BlackArch groups found. Make sure the BlackArch repo was added and pacman database updated."
  exit 1
fi

CHOICE_ITEMS=()
CHOICE_ITEMS+=("blackarch" "Install ALL BlackArch tools (very large)" OFF)
for grp in "${raw_groups[@]}"; do
  short="${grp#blackarch-}"
  CHOICE_ITEMS+=("$grp" "$short" OFF)
done

CHOICES=$(whiptail --title "BlackArch installer" --checklist \
"Select BlackArch groups to install (SPACE to toggle, TAB to move):" 25 80 20 \
"${CHOICE_ITEMS[@]}" 3>&1 1>&2 2>&3) || {
  warn "User cancelled selection. Exiting."
  exit 0
}

eval "selected=($CHOICES)"

if [ ${#selected[@]} -eq 0 ]; then
  warn "No groups selected. Nothing to do."
  exit 0
fi

for s in "${selected[@]}"; do
  s=${s//\"/}
  if [ "$s" = "blackarch" ]; then
    warn "You chose to install the entire BlackArch repository (all tools). This is very large and may take a lot of time and disk space."
    read -rp "$(echo -e "${B}Are you sure you want to proceed with installing ALL BlackArch tools? (y/N): ${E}")" confirm_all
    if [[ ! "$confirm_all" =~ ^[Yy]$ ]]; then
      warn "Skipping 'blackarch' install as requested."
      newsel=()
      for t in "${selected[@]}"; do
        if [ "${t//\"/}" != "blackarch" ]; then newsel+=("$t"); fi
      done
      selected=("${newsel[@]}")
    fi
    break
  fi
done

if [ ${#selected[@]} -eq 0 ]; then
  warn "No groups left to install. Exiting."
  exit 0
fi

failed=()
succeeded=()
for raw in "${selected[@]}"; do
  group="${raw//\"/}"
  info "Installing group: ${group} ..."
  retries=3
  success=false
  while [ $retries -gt 0 ]; do
    if sudo pacman -S --noconfirm --needed "$group"; then
      ok "Installed: $group"
      success=true
      succeeded+=("$group")
      break
    else
      warn "Install failed for $group. Retrying... attempts left: $((retries-1))"
      retries=$((retries-1))
      sleep 3
      sudo pacman -Sy
    fi
  done
  if ! $success; then
    err "Failed to install group: $group"
    failed+=("$group")
  fi
done

echo
if [ ${#succeeded[@]} -ne 0 ]; then
  ok "Successfully installed groups:"
  for g in "${succeeded[@]}"; do printf "  - %s\n" "$g"; done
fi

if [ ${#failed[@]} -ne 0 ]; then
  err "Failed to install the following groups:"
  for g in "${failed[@]}"; do printf "  - %s\n" "$g"; done
  warn "You can re-run this script to try again for the failed groups."
else
  ok "All selected groups installed successfully."
fi

exit 0
